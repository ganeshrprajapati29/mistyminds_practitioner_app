import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/feedback.dart';
import '../../../../core/utils/media_picker.dart';
import '../../../../core/widgets/misty_buttons.dart';
import '../../../../core/widgets/misty_profile_avatar.dart';
import '../../../../core/widgets/misty_text_field.dart';
import '../../../../data/models/psychologist.dart';
import '../../../../state/providers.dart';
import '../widgets/profile_sub_page.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final Psychologist _p = ref.read(profileProvider).requireValue;
  bool _uploadingPhoto = false;

  Future<void> _changePhoto() async {
    final PickedFile? photo = await pickPhoto(context);
    if (photo == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref
          .read(profileProvider.notifier)
          .uploadPhoto(photo.bytes, photo.name),
    );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (ok) AppFeedback.toast(context, 'Profile photo updated.');
  }

  late final TextEditingController _name = TextEditingController(text: _p.name);
  late final TextEditingController _title = TextEditingController(
    text: _p.title,
  );
  late final TextEditingController _email = TextEditingController(
    text: _p.email,
  );
  late final TextEditingController _phone = TextEditingController(
    text: _p.phone,
  );
  late final TextEditingController _bio = TextEditingController(text: _p.bio);
  bool _saving = false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _name,
      _title,
      _email,
      _phone,
      _bio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final bool ok = await AppFeedback.guard(
      context,
      () => ref
          .read(profileProvider.notifier)
          .save(
            _p.copyWith(
              name: _name.text.trim(),
              title: _title.text.trim(),
              email: _email.text.trim(),
              phone: _phone.text.trim(),
              bio: _bio.text.trim(),
            ),
          ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) return;
    AppFeedback.toast(context, 'Profile updated');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSubPage(
      title: 'Edit Profile',
      footer: MistyPrimaryButton(
        label: 'Save Changes',
        isLoading: _saving,
        onPressed: _save,
      ),
      children: <Widget>[
        Center(
          child: Stack(
            children: <Widget>[
              MistyProfileAvatar(
                name: _p.name,
                photoUrl: ref.watch(profileProvider).valueOrNull?.photoUrl,
                size: 96,
                ring: true,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Material(
                  color: AppColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _uploadingPhoto ? null : _changePhoto,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _uploadingPhoto
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Center(
          child: Text(
            'Clients see this photo and name',
            style: AppTypography.caption,
          ),
        ),
        const SizedBox(height: AppSizes.xl),
        Form(
          key: _form,
          child: Column(
            children: <Widget>[
              MistyTextField(
                label: 'Display name',
                controller: _name,
                validator: (String? v) => Validators.required(v, 'Name'),
              ),
              const SizedBox(height: AppSizes.lg),
              MistyTextField(label: 'Professional title', controller: _title),
              const SizedBox(height: AppSizes.lg),
              MistyTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.emailOrPhone,
              ),
              const SizedBox(height: AppSizes.lg),
              MistyTextField(
                label: 'Mobile',
                controller: _phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSizes.lg),
              MistyTextField(
                label: 'About me',
                controller: _bio,
                maxLines: 5,
                maxLength: 400,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
