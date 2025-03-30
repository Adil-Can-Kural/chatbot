<script setup>
import { ref } from 'vue';
import { useForm } from '@inertiajs/inertia-vue3';
import JetActionSection from '@/Jetstream/ActionSection.vue';
import JetDialogModal from '@/Jetstream/DialogModal.vue';
import JetDangerButton from '@/Jetstream/DangerButton.vue';
import JetInput from '@/Jetstream/Input.vue';
import JetInputError from '@/Jetstream/InputError.vue';
import JetSecondaryButton from '@/Jetstream/SecondaryButton.vue';

const confirmingUserDeletion = ref(false);
const passwordInput = ref(null);

const form = useForm({
    password: '',
});

const confirmUserDeletion = () => {
    confirmingUserDeletion.value = true;

    setTimeout(() => passwordInput.value.focus(), 250);
};

const deleteUser = () => {
    form.delete(route('current-user.destroy'), {
        preserveScroll: true,
        onSuccess: () => closeModal(),
        onError: () => passwordInput.value.focus(),
        onFinish: () => form.reset(),
    });
};

const closeModal = () => {
    confirmingUserDeletion.value = false;

    form.reset();
};
</script>

<template>
    <JetActionSection>
        <template #title>
            Hesabı Sil
        </template>

        <template #description>
            Hesabınızı kalıcı olarak silin.
        </template>

        <template #content>
            <div class="max-w-xl text-sm text-gray-600">
                Hesabınız silindiğinde, tüm kaynakları ve verileri kalıcı olarak silinecektir. Hesabınızı silmeden önce, lütfen saklamak istediğiniz verileri veya bilgileri indirin.
            </div>

            <div class="mt-5">
                <JetDangerButton @click="confirmUserDeletion">
                    Hesabı Sil
                </JetDangerButton>
            </div>

            <!-- Delete Account Confirmation Modal -->
            <JetDialogModal :show="confirmingUserDeletion" @close="closeModal">
                <template #title>
                    Hesabı Sil
                </template>

                <template #content>
                    Hesabınızı silmek istediğinizden emin misiniz? Hesabınız silindiğinde, tüm kaynakları ve verileri kalıcı olarak silinecektir. Hesabınızı kalıcı olarak silmek istediğinizi onaylamak için lütfen şifrenizi girin.

                    <div class="mt-4">
                        <JetInput
                            ref="passwordInput"
                            v-model="form.password"
                            type="password"
                            class="mt-1 block w-3/4"
                            placeholder="Şifre"
                            @keyup.enter="deleteUser"
                        />

                        <JetInputError :message="form.errors.password" class="mt-2" />
                    </div>
                </template>

                <template #footer>
                    <JetSecondaryButton @click="closeModal">
                        İptal
                    </JetSecondaryButton>

                    <JetDangerButton
                        class="ml-3"
                        :class="{ 'opacity-25': form.processing }"
                        :disabled="form.processing"
                        @click="deleteUser"
                    >
                        Hesabı Sil
                    </JetDangerButton>
                </template>
            </JetDialogModal>
        </template>
    </JetActionSection>
</template>
