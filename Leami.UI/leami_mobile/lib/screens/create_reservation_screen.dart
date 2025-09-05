import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import '../providers/reservation_provider.dart';
import '../providers/auth_provider.dart';

class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _submitting = false;

  // ====== VALIDATORS ======

  String? _futureDateTimeValidator(Object? _) {
    final form = _formKey.currentState;
    if (form == null) return null;

    final date = form.fields['reservationDate']?.value as DateTime?;
    // ⬇ vrijeme je DateTime? tokom validacije (ne String!)
    final timeDt = form.fields['reservationTimeObj']?.value as DateTime?;

    if (date == null || timeDt == null) {
      return 'Datum i vrijeme su obavezni.';
    }

    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      timeDt.hour,
      timeDt.minute,
    );
    if (dt.isBefore(DateTime.now())) {
      return 'Datum i vrijeme rezervacije ne smiju biti u prošlosti.';
    }
    return null;
  }

  // 2) Telefon – obavezan + format
  String? _phoneValidator(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Kontakt telefon je obavezan.';
    }
    final v = val.trim();
    final re = RegExp(r'^\+?[0-9\s\-\/]{6,20}$');
    if (!re.hasMatch(v)) return 'Telefon nije u validnom formatu.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: Scaffold(
        appBar: AppBar(title: const Text('Napravi rezervaciju')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FormBuilder(
              key: _formKey,
              child: ListView(
                children: [
                  // Required: ReservationDate
                  FormBuilderDateTimePicker(
                    name: 'reservationDate',
                    inputType: InputType.date,
                    decoration: const InputDecoration(labelText: 'Datum'),
                    firstDate: DateTime.now(),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Datum je obavezan.',
                      ),
                      _futureDateTimeValidator,
                    ]),
                    onChanged: (_) {
                      // kad promijeniš datum, revalidiraj vrijeme (cross-field)
                      _formKey.currentState?.fields['reservationTimeObj']
                          ?.validate();
                    },
                  ),
                  const SizedBox(height: 12),

                  FormBuilderDateTimePicker(
                    name: 'reservationTimeObj',
                    inputType: InputType.time,
                    decoration: const InputDecoration(labelText: 'Vrijeme'),
                    initialTime: const TimeOfDay(hour: 18, minute: 0),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Vrijeme je obavezno.',
                      ),
                      _futureDateTimeValidator,
                    ]),
                    // Tokom VALIDACIJE vrijednost je DateTime; transformer je samo za SAVE.
                    valueTransformer: (DateTime? dt) {
                      if (dt == null) return null;
                      final h = dt.hour.toString().padLeft(2, '0');
                      final m = dt.minute.toString().padLeft(2, '0');
                      return '$h:$m'; // backend: "HH:mm"
                    },
                  ),
                  const SizedBox(height: 12),

                  // Required: NumberOfGuests 1..100
                  FormBuilderTextField(
                    name: 'numberOfGuests',
                    decoration: const InputDecoration(
                      labelText: 'Broj gostiju',
                    ),
                    keyboardType: TextInputType.number,
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Broj gostiju je obavezan.',
                      ),
                      FormBuilderValidators.integer(
                        errorText: 'Unesite cijeli broj.',
                      ),
                      FormBuilderValidators.min(
                        1,
                        errorText: 'Minimalno 1 gost.',
                      ),
                      FormBuilderValidators.max(
                        100,
                        errorText: 'Maksimalno 100 gostiju.',
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // Optional: NumberOfMinors 0..100 (backend Range(0,100))
                  FormBuilderTextField(
                    name: 'numberOfMinors',
                    decoration: const InputDecoration(
                      labelText: 'Broj maloljetnika (opcionalno)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.isEmpty) return null;
                      final n = int.tryParse(val);
                      if (n == null) return 'Unesite broj.';
                      if (n < 0 || n > 100)
                        return 'Broj maloljetnika može biti između 0 i 100.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Required: ContactPhone + format
                  FormBuilderTextField(
                    name: 'contactPhone',
                    decoration: const InputDecoration(
                      labelText: 'Kontakt telefon',
                    ),
                    validator: (val) => _phoneValidator(val),
                  ),
                  const SizedBox(height: 12),

                  // Optional: ReservationReason max 1000
                  FormBuilderTextField(
                    name: 'reservationReason',
                    decoration: const InputDecoration(
                      labelText: 'Razlog (opcionalno)',
                    ),
                    maxLines: 2,
                    validator: (val) => _optionalMaxLen(
                      val,
                      100,
                      'Razlog može imati najviše 100 karaktera.',
                    ),
                  ),

                  // Specijalni zahtjevi (opcionalno, max 2000 – usklađeno s backendom)
                  FormBuilderTextField(
                    name: 'specialRequests',
                    decoration: const InputDecoration(
                      labelText: 'Specijalni zahtjevi (opcionalno)',
                    ),
                    maxLines: 3,
                    validator: (val) => _optionalMaxLen(
                      val,
                      200,
                      'Posebni zahtjevi mogu imati najviše 200 karaktera.',
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Potvrdi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (!form.saveAndValidate()) return;

    final userId = AuthProvider.user?.id;
    if (userId == null) {
      _showErr('Niste prijavljeni.');
      return;
    }

    final vals = form.value;

    // Parse opcionalnog broja maloljetnika
    int? minors;
    final minorsRaw = vals['numberOfMinors'] as String?;
    if (minorsRaw != null && minorsRaw.trim().isNotEmpty) {
      minors = int.tryParse(minorsRaw.trim());
    }
    // opcionalna polja: trim + prazno => null
    String? _nn(String? s) {
      if (s == null) return null;
      final t = s.trim();
      return t.isEmpty ? null : t;
    }

    final DateTime date = vals['reservationDate'] as DateTime;

    final String hhmm = vals['reservationTimeObj'] as String; // npr. "18:00"
    final String hhmmss = '$hhmm:00'; // -> "18:00:00"
    final reason = _nn(vals['reservationReason'] as String?);
    final special = _nn(vals['specialRequests'] as String?);

    final body = {
      "reservationDate": _fmtYmd(date), // "2025-10-09"  ✅ DateOnly friendly
      "reservationTime": hhmmss, // "18:00:00"    ✅ TimeOnly friendly
      "numberOfGuests":
          int.tryParse(vals['numberOfGuests'] as String? ?? '') ?? 1,
      "reservationStatus": 2,
      "userId": userId,
      "reservationReason": reason,
      "numberOfMinors": minors,
      "contactPhone": vals["contactPhone"],
      // DTO ima 'SpeciaLRequest' (singular, čudna kapitalizacija).
      // System.Text.Json po defaultu camelCase -> "speciaLRequest"
      "speciaLRequest": special,
    };

    setState(() => _submitting = true);
    try {
      await context.read<ReservationProvider>().insert(body);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showErr('Greška pri kreiranju: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _optionalMaxLen(String? val, int max, String msg) {
    final t = val?.trim() ?? '';
    if (t.isEmpty) return null; // ⬅️ ako je prazno, OK
    if (t.length > max) return msg; // ⬅️ ako je unešeno, provjeri max
    return null;
  }

  String _fmtYmd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  void _showErr(String m) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Greška'),
        content: Text(m),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
