<script setup>
import { reactive, defineProps, toRefs, onMounted, onUnmounted, ref } from 'vue'
import moment from 'moment';
import 'emoji-picker-element';

import AppLayout from '@/Layouts/AppLayout.vue';
import TailRight from '@/Jetstream/Components/Chat/TailRight.vue';
import TailLeft from '@/Jetstream/Components/Chat/TailLeft.vue';
import LoaderDot from '@/Jetstream/Components/Loader/Dot.vue';
import JetDialogModal from '@/Jetstream/DialogModal.vue';
import JetDropdown from '@/Jetstream/Dropdown.vue';
import JetDropdownLink from '@/Jetstream/DropdownLink.vue';
import JetSecondaryButton from '@/Jetstream/SecondaryButton.vue';
import JetInput from '@/Jetstream/Input.vue';
import Toast from '@/Jetstream/Components/System/Toast.vue';

import { Inertia } from '@inertiajs/inertia';
import { usePage } from '@inertiajs/inertia-vue3';

// Moment.js Türkçe yerelleştirme
moment.locale('tr', {
    months: 'Ocak_Şubat_Mart_Nisan_Mayıs_Haziran_Temmuz_Ağustos_Eylül_Ekim_Kasım_Aralık'.split('_'),
    monthsShort: 'Oca_Şub_Mar_Nis_May_Haz_Tem_Ağu_Eyl_Eki_Kas_Ara'.split('_'),
    weekdays: 'Pazar_Pazartesi_Salı_Çarşamba_Perşembe_Cuma_Cumartesi'.split('_'),
    weekdaysShort: 'Paz_Pzt_Sal_Çar_Per_Cum_Cmt'.split('_'),
    weekdaysMin: 'Pz_Pt_Sa_Ça_Pe_Cu_Ct'.split('_'),
    longDateFormat: {
        LT: 'HH:mm',
        LTS: 'HH:mm:ss',
        L: 'DD.MM.YYYY',
        LL: 'D MMMM YYYY',
        LLL: 'D MMMM YYYY HH:mm',
        LLLL: 'dddd, D MMMM YYYY HH:mm'
    },
    calendar: {
        sameDay: '[Bugün]',
        nextDay: '[Yarın]',
        nextWeek: 'dddd',
        lastDay: '[Dün]',
        lastWeek: '[Geçen] dddd',
        sameElse: 'L'
    },
    relativeTime: {
        future: '%s sonra',
        past: '%s önce',
        s: 'birkaç saniye',
        m: 'bir dakika',
        mm: '%d dakika',
        h: 'bir saat',
        hh: '%d saat',
        d: 'bir gün',
        dd: '%d gün',
        M: 'bir ay',
        MM: '%d ay',
        y: 'bir yıl',
        yy: '%d yıl'
    }
});

moment.locale('tr');

const user = usePage().props.value.user

let sections = {};
onMounted(() => {
    // Kullanıcı profilini yükle
    loadUserProfile();
    
    // Tüm odalar için okunmamış mesaj sayısını hesapla
    rooms.data.forEach(room => {
        unreadCounts.value[room.id] = calculateUnreadCount(room);
    });
    
    // Elif'i otomatik olarak kişiler listesine ekle
    const elifRoomId = getElifRoomId();
    const existingElif = rooms.data.find(room => room.name === 'Elif');
    
    if (existingElif) {
        // Eğer Elif zaten varsa, sohbet geçmişini yükle ve sohbeti aç
        if (existingElif.id) {
            // Elif'in oda ID'sini güncelle
            saveElifRoomId(existingElif.id);
            
            // Sohbet geçmişini yükle
            const savedMessages = loadChatHistory();
            if (savedMessages && savedMessages.length > 0) {
                // Sohbeti aç
                changeRoom(existingElif);
            }
        }
    } else {
        // Elif yoksa ekle
        addElifToContacts();
    }
    
    // Serdar'ı otomatik olarak kişiler listesine ekle
    const serdarRoomId = getSerdarRoomId();
    const existingSerdar = rooms.data.find(room => room.name === 'Serdar');
    
    if (existingSerdar) {
        // Eğer Serdar zaten varsa, sohbet geçmişini yükle
        if (existingSerdar.id) {
            // Serdar'ın oda ID'sini güncelle
            saveSerdarRoomId(existingSerdar.id);
            
            // Sohbet geçmişini yükle
            const savedSerdarMessages = loadSerdarChatHistory();
            if (savedSerdarMessages && savedSerdarMessages.length > 0) {
                // Sohbeti aç (isteğe bağlı)
                // changeRoom(existingSerdar);
            }
        }
    } else {
        // Serdar yoksa ekle
        addSerdarToContacts();
    }
    
    // Nazlı'nın otomatik olarak kişiler listesine ekle
    const nazliRoomId = getNazliRoomId();
    const existingNazli = rooms.data.find(room => room.name === 'Nazlı');
    
    if (existingNazli) {
        // Eğer Nazlı zaten varsa, sohbet geçmişini yükle
        if (existingNazli.id) {
            // Nazlı'nın oda ID'sini güncelle
            saveNazliRoomId(existingNazli.id);
            
            // Sohbet geçmişini yükle
            const savedNazliMessages = loadNazliChatHistory();
            if (savedNazliMessages && savedNazliMessages.length > 0) {
                // Sohbeti aç (isteğe bağlı)
                // changeRoom(existingNazli);
            }
        }
    } else {
        // Nazlı yoksa ekle
        addNazliToContacts();
    }
    
    Echo.private(`user.${user.id}`)
        .subscribed(() => {
        })
        .listen('.receive-message', (event) => {
            let roomIndex = rooms.data.findIndex((room => room.id == event.room.id));
            if (roomIndex !== -1) {
                // Odanın son mesajını güncelle
                if (event.message) {
                    rooms.data[roomIndex].last_message = {
                        ...event.message,
                        created_at: event.message.created_at ? new Date(event.message.created_at) : new Date()
                    };
                    
                    // Eğer bu oda şu anda seçili değilse, okunmamış mesaj sayısını artır
                    if (selectedRoom.id !== event.room.id) {
                        unreadCounts.value[event.room.id] = (unreadCounts.value[event.room.id] || 0) + 1;
                    }
                }
                
                // Eğer bu oda şu anda seçiliyse, mesajları da güncelle
                if (selectedRoom.id === event.room.id) {
                    // Yeni mesaj geldiğinde, mesajlar listesine ekle
                    const messageExists = selectedRoom.messages.some(m => m.id === event.message.id);
                    if (!messageExists && event.message) {
                        selectedRoom.messages.push({
                            ...event.message,
                            created_at: event.message.created_at ? new Date(event.message.created_at) : new Date()
                        });
                        scrollToBottomOfChat();
                    }
                }
            }
        });
    
    // Mesaj gönderildiğinde de odaların son mesajlarını güncelle
    Echo.private(`user.${user.id}`)
        .listen('.send-message', (event) => {
            let roomIndex = rooms.data.findIndex((room => room.id == event.room.id));
            if (roomIndex !== -1 && event.message) {
                // Odanın son mesajını güncelle
                rooms.data[roomIndex].last_message = {
                    ...event.message,
                    created_at: event.message.created_at ? new Date(event.message.created_at) : new Date()
                };
            }
        });
        
    var i = 0;
    const mainView = document.querySelector("#main")
    let theText = ''
    mainView.onscroll = function () {
        var scrollPosition = mainView.scrollTop;
        let newArr = []
        for (i in sections) {
            if (sections[i] + 30 <= scrollPosition) {
                newArr.push(i)
            }
        }
        if (newArr.length > 0) {
            let viewedDiv = newArr[newArr.length - 1]
            if (document.querySelector(`#${viewedDiv} .text`)) {
                if (theText != document.querySelector(`#${viewedDiv} .text`).textContent) {
                    theText = document.querySelector(`#${viewedDiv} .text`).textContent
                    if (document.getElementById('curdate')) {
                        document.getElementById('curdate').innerHTML = theText
                    }
                }
            }
        }
    };

    // Otomatik sohbet yenileme için interval
    const refreshInterval = setInterval(() => {
        if (selectedRoom.id) {
            refreshMessages();
        }
    }, 10000); // 10 saniyede bir yenile

    // Component unmount olduğunda interval'i temizle
    onUnmounted(() => {
        clearInterval(refreshInterval);
    });
})

// Mesajları yenileme fonksiyonu
const refreshMessages = async () => {
    try {
        const response = await axios.get(`/rooms/${selectedRoom.id}/messages`);
        if (response.data.messages) {
            // Yeni mesajları kontrol et
            if (response.data.messages.length > selectedRoom.messages.length) {
                // Yeni mesajlar var, güncelle ve tarih formatını düzelt
                selectedRoom.messages = response.data.messages.map(message => ({
                    ...message,
                    created_at: message.created_at ? new Date(message.created_at) : new Date()
                }));
                scrollToBottomOfChat();
            }
        }
    } catch (error) {
        console.error('Mesajlar yenilenirken hata oluştu:', error);
    }
};

const app = reactive({
    title: 'Panel'
})

const setTitle = (newTitle) => {
    app.title = newTitle
}

const toast = reactive({
    show: false,
    message: "",
    type: "error",
})

const showToast = ({ message, type }) => {
    toast.show = true;
    toast.message = message;
    toast.type = type;
    hideToast();
}

const hideToast = async () => {
    await wait(5000);
    toast.show = false;
    toast.message = "";
    toast.type = "success";
}

const wait = (timeout) => {
    return new Promise((resolve) => {
        setTimeout(resolve, timeout);
    });
}

const props = defineProps({
    rooms: Object,
});

const rooms = reactive({
    data: props.rooms.data
});

const selectedRoom = reactive({
    profile_picture: null,
    name: null,
    id: null,
    messages: [],
    isChangingRoom: false,
    form: {
        message: null,
        isProcessing: false
    }
})

// Okunmamış mesaj sayısını hesapla
const calculateUnreadCount = (room) => {
  if (!room || !room.last_message) return 0;
  
  // Eğer oda seçili ise, okunmamış mesaj yok
  if (selectedRoom.id === room.id) return 0;
  
  // Yerel depolamadan okunmamış mesaj sayısını al
  const lastReadTimestamp = localStorage.getItem(`lastRead_${room.id}`);
  
  // Eğer son mesaj zamanı, son okuma zamanından sonra ise, okunmamış mesaj var
  if (lastReadTimestamp) {
    const lastReadDate = new Date(lastReadTimestamp);
    const lastMessageDate = new Date(room.last_message.created_at);
    
    if (lastMessageDate > lastReadDate) {
      return 1; // Şimdilik sadece 1 gösteriyoruz, ileride gerçek sayıyı hesaplayabiliriz
    }
  } else if (room.last_message) {
    // Hiç okunmamış ise ve mesaj varsa
    return 1;
  }
  
  return 0;
};

// Oda değiştiğinde son okuma zamanını güncelle
const updateLastReadTimestamp = (roomId) => {
  if (!roomId) return;
  
  // Şu anki zamanı kaydet
  localStorage.setItem(`lastRead_${roomId}`, new Date().toISOString());
  
  // Okunmamış mesaj sayısını sıfırla
  if (unreadCounts.value[roomId]) {
    unreadCounts.value[roomId] = 0;
  }
};

const changeRoom = async (room) => {
    selectRoom(room)
    setTitle(room.name)
    selectedRoom.isChangingRoom = true
    selectedRoom.messages = []
    
    // Oda değiştiğinde son okuma zamanını güncelle
    updateLastReadTimestamp(room.id);
    
    // Eğer Elif ile konuşuyorsak, yerel depolamadan sohbet geçmişini yükle
    if (room.name === 'Elif') {
        const savedMessages = loadChatHistory();
        if (savedMessages && savedMessages.length > 0) {
            selectedRoom.messages = savedMessages;
            selectedRoom.isChangingRoom = false;
            scrollToBottomOfChat();
            return;
        }
    }
    
    // Eğer Serdar ile konuşuyorsak, yerel depolamadan sohbet geçmişini yükle
    if (room.name === 'Serdar') {
        const savedSerdarMessages = loadSerdarChatHistory();
        console.log('Serdar sohbet geçmişi yüklendi:', savedSerdarMessages);
        if (savedSerdarMessages && savedSerdarMessages.length > 0) {
            selectedRoom.messages = savedSerdarMessages;
            selectedRoom.isChangingRoom = false;
            scrollToBottomOfChat();
            return;
        }
    }

    // Eğer Nazlı ile konuşuyorsak, yerel depolamadan sohbet geçmişini yükle
    if (room.name === 'Nazlı') {
        const savedNazliMessages = loadNazliChatHistory();
        console.log('Nazlı sohbet geçmişi yüklendi:', savedNazliMessages);
        if (savedNazliMessages && savedNazliMessages.length > 0) {
            selectedRoom.messages = savedNazliMessages;
            selectedRoom.isChangingRoom = false;
            scrollToBottomOfChat();
            return;
        }
    }
    
    try {
        const response = await axios.get(`/rooms/${room.id}/messages`)
        if (response.data.messages) {
            // Mesajları işle ve tarih formatını düzelt
            selectedRoom.messages = response.data.messages.map(message => ({
                ...message,
                created_at: message.created_at ? new Date(message.created_at) : new Date()
            }));
        }
    } catch (e) {
        if (e.response && e.response.data && e.response.data.errors) {
            // Handle error
        }
    }
    
    selectedRoom.isChangingRoom = false
    scrollToBottomOfChat()
    await new Promise((resolve) => setTimeout(resolve, 1))

    const section = document.querySelectorAll("main .dates");
    const m = document.querySelector("main")
    Array.prototype.forEach.call(section, function (e) {
        sections[e.id] = e.offsetTop - m.offsetTop;
    });
}

const scrollToBottomOfChat = async () => {
    await new Promise((resolve) => setTimeout(resolve, 0.3))
    var objDiv = document.getElementById("main");
    objDiv.scrollTop = objDiv.scrollHeight;
}

const resetRoom = () => {
    selectedRoom.profile_picture = null
    selectedRoom.name = null
    selectedRoom.id = null
}

const selectRoom = (room) => {
    if (selectedRoom.id) {
        Echo.leave(`room.message.${selectedRoom.id}`)
    }

    selectedRoom.id = room.id
    selectedRoom.profile_picture = room.profile_picture
    selectedRoom.name = room.name

    Echo.private(`room.message.${selectedRoom.id}`)
        .subscribed(() => {
        })
        .listen('.send-message', (event) => {
            // Mesajı ekle
            const messageExists = selectedRoom.messages.some(m => m.id === event.message.id);
            if (!messageExists && event.message) {
                selectedRoom.messages.push({
                    ...event.message,
                    created_at: event.message.created_at ? new Date(event.message.created_at) : new Date()
                });
                scrollToBottomOfChat();
            }
            
            // Odanın son mesajını güncelle
            let roomIndex = rooms.data.findIndex((room => room.id == selectedRoom.id));
            if (roomIndex !== -1) {
                rooms.data[roomIndex].last_message = {
                    ...event.message,
                    created_at: event.message.created_at ? new Date(event.message.created_at) : new Date()
                };
            }
        });
}

// Chatbot için değişkenler
const chatbotRoom = ref(null);
const chatbotMessages = ref([]);
const isTyping = ref(false);
const groqApiKey = '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'; // Groq API anahtarı

// Tersleme mantığı için değişkenler
const unansweredCounters = ref({ Elif: 0, Serdar: 0, Nazli: 0 });
const firstUnansweredTimestamps = ref({ Elif: null, Serdar: null, Nazli: null });
const SNAPPY_THRESHOLD_COUNT = 3; // Tersleme için gereken ardışık cevapsız mesaj sayısı
const SNAPPY_THRESHOLD_MINUTES = 2; // Tersleme için gereken süre (dakika)

// Stable Diffusion için değişkenler
const isGeneratingImage = ref(false);
const stableDiffusionApiKey = 'sk-'; // Buraya Stable Diffusion API anahtarınızı ekleyin

// Kullanıcı profili için değişken
const userProfile = ref({
  name: '',
  age: '',
  location: '',
  interests: [],
  otherInfo: {}
});

// Okunmamış mesaj sayısını takip etmek için değişken
const unreadCounts = ref({});

// Kullanıcı profilini yerel depolamadan yükle
const loadUserProfile = () => {
  try {
    const savedProfile = localStorage.getItem('elifUserProfile');
    if (savedProfile) {
      userProfile.value = JSON.parse(savedProfile);
    }
  } catch (error) {
    console.error('Kullanıcı profili yüklenirken hata:', error);
  }
};

// Kullanıcı profilini yerel depolamaya kaydet
const saveUserProfile = () => {
  try {
    localStorage.setItem('elifUserProfile', JSON.stringify(userProfile.value));
  } catch (error) {
    console.error('Kullanıcı profili kaydedilirken hata:', error);
  }
};

// Yerel depolamadan sohbet geçmişini yükle
const loadChatHistory = () => {
  try {
    const savedHistory = localStorage.getItem('elifChatHistory');
    if (savedHistory) {
      const parsedHistory = JSON.parse(savedHistory);
      // Tarih nesnelerini düzelt
      return parsedHistory.map(msg => ({
        ...msg,
        created_at: new Date(msg.created_at)
      }));
    }
  } catch (error) {
    console.error('Sohbet geçmişi yüklenirken hata:', error);
  }
  return [];
};

// Sohbet geçmişini yerel depolamaya kaydet
const saveChatHistory = (messages) => {
  try {
    localStorage.setItem('elifChatHistory', JSON.stringify(messages));
  } catch (error) {
    console.error('Sohbet geçmişi kaydedilirken hata:', error);
  }
};

// Elif'in oda ID'sini yerel depolamada sakla
const saveElifRoomId = (roomId) => {
  try {
    localStorage.setItem('elifRoomId', roomId.toString());
  } catch (error) {
    console.error('Elif oda ID kaydedilirken hata:', error);
  }
};

// Elif'in oda ID'sini yerel depolamadan al
const getElifRoomId = () => {
  try {
    return localStorage.getItem('elifRoomId');
  } catch (error) {
    console.error('Elif oda ID alınırken hata:', error);
    return null;
  }
};

// Serdar'ın oda ID'sini yerel depolamada sakla
const saveSerdarRoomId = (roomId) => {
  try {
    localStorage.setItem('serdarRoomId', roomId.toString());
  } catch (error) {
    console.error('Serdar oda ID kaydedilirken hata:', error);
  }
};

// Serdar'ın oda ID'sini yerel depolamadan al
const getSerdarRoomId = () => {
  try {
    return localStorage.getItem('serdarRoomId');
  } catch (error) {
    console.error('Serdar oda ID alınırken hata:', error);
    return null;
  }
};

// Yerel depolamadan Serdar'ın sohbet geçmişini yükle
const loadSerdarChatHistory = () => {
  try {
    const savedHistory = localStorage.getItem('serdarChatHistory');
    if (savedHistory) {
      const parsedHistory = JSON.parse(savedHistory);
      // Tarih nesnelerini düzelt
      return parsedHistory.map(msg => ({
        ...msg,
        created_at: new Date(msg.created_at)
      }));
    }
  } catch (error) {
    console.error('Serdar sohbet geçmişi yüklenirken hata:', error);
  }
  return [];
};

// Serdar'ın sohbet geçmişini yerel depolamaya kaydet
const saveSerdarChatHistory = (messages) => {
  try {
    localStorage.setItem('serdarChatHistory', JSON.stringify(messages));
  } catch (error) {
    console.error('Serdar sohbet geçmişi kaydedilirken hata:', error);
  }
};

// Elif'i kişiler listesine ekle
const addElifToContacts = () => {
    // Eğer Elif zaten kişiler listesinde varsa, ekleme
    const existingElif = rooms.data.find(room => room.name === 'Elif');
    if (existingElif) {
        // Sessizce geç, uyarı gösterme
        return;
    }
    
    // Yeni bir oda oluştur ve kişiler listesine ekle
    axios.post('/rooms', {
        name: 'Elif',
        is_bot: false // Normal bir kullanıcı olarak göster
    }).then(response => {
        if (response.data && response.data.success) {
            // Yeni oda bilgisini al ve odalar listesine ekle
            const newRoom = response.data.data.room;
            rooms.data.push({
                ...newRoom,
                profile_picture: 'https://i.pravatar.cc/150?img=5', // Kadın avatar
                last_message: {
                    message: 'Merhaba! Nasılsın?',
                    created_at: new Date()
                }
            });
            
            // Elif'in oda ID'sini yerel depolamada sakla
            saveElifRoomId(newRoom.id);
            
            // Otomatik olarak Elif ile sohbeti aç
            changeRoom(newRoom);
        }
    }).catch(error => {
        console.error('Elif eklenirken hata:', error);
    });
};

// Serdar'ı kişiler listesine ekle
const addSerdarToContacts = () => {
    // Eğer Serdar zaten kişiler listesinde varsa, ekleme
    const existingSerdar = rooms.data.find(room => room.name === 'Serdar');
    if (existingSerdar) {
        // Sessizce geç, uyarı gösterme
        return;
    }
    
    // Yeni bir oda oluştur ve kişiler listesine ekle
    axios.post('/rooms', {
        name: 'Serdar',
        is_bot: false // Normal bir kullanıcı olarak göster
    }).then(response => {
        if (response.data && response.data.success) {
            // Yeni oda bilgisini al ve odalar listesine ekle
            const newRoom = response.data.data.room;
            rooms.data.push({
                ...newRoom,
                profile_picture: 'https://i.pravatar.cc/150?img=12', // Erkek avatar
                last_message: {
                    message: 'Selam... Ne istiyorsun?',
                    created_at: new Date()
                }
            });
            
            // Serdar'ın oda ID'sini yerel depolamada sakla
            saveSerdarRoomId(newRoom.id);
        }
    }).catch(error => {
        console.error('Serdar eklenirken hata:', error);
    });
};

// Nazlı'nın oda ID'sini yerel depolamada sakla
const saveNazliRoomId = (roomId) => {
  try {
    localStorage.setItem('nazliRoomId', roomId.toString());
  } catch (error) {
    console.error('Nazlı oda ID kaydedilirken hata:', error);
  }
};

// Nazlı'nın oda ID'sini yerel depolamadan al
const getNazliRoomId = () => {
  try {
    return localStorage.getItem('nazliRoomId');
  } catch (error) {
    console.error('Nazlı oda ID alınırken hata:', error);
    return null;
  }
};

// Yerel depolamadan Nazlı'nın sohbet geçmişini yükle
const loadNazliChatHistory = () => {
  try {
    const savedHistory = localStorage.getItem('nazliChatHistory');
    if (savedHistory) {
      const parsedHistory = JSON.parse(savedHistory);
      // Tarih nesnelerini düzelt
      return parsedHistory.map(msg => ({
        ...msg,
        created_at: new Date(msg.created_at)
      }));
    }
  } catch (error) {
    console.error('Nazlı sohbet geçmişi yüklenirken hata:', error);
  }
  return [];
};

// Nazlı'nın sohbet geçmişini yerel depolamaya kaydet
const saveNazliChatHistory = (messages) => {
  try {
    localStorage.setItem('nazliChatHistory', JSON.stringify(messages));
  } catch (error) {
    console.error('Nazlı sohbet geçmişi kaydedilirken hata:', error);
  }
};

// Nazlı'yı kişiler listesine ekle
const addNazliToContacts = () => {
    // Eğer Nazlı zaten kişiler listesinde varsa, ekleme
    const existingNazli = rooms.data.find(room => room.name === 'Nazlı');
    if (existingNazli) {
        return;
    }
    
    // Yeni bir oda oluştur ve kişiler listesine ekle
    axios.post('/rooms', {
        name: 'Nazlı',
        is_bot: false // Normal bir kullanıcı olarak göster
    }).then(response => {
        if (response.data && response.data.success) {
            // Yeni oda bilgisini al ve odalar listesine ekle
            const newRoom = response.data.data.room;
            rooms.data.push({
                ...newRoom,
                profile_picture: 'https://i.pravatar.cc/150?img=6', // Nazlı için farklı bir avatar
                last_message: {
                    message: 'Merhaba, nasılsın?',
                    created_at: new Date()
                }
            });
            
            // Nazlı'nın oda ID'sini yerel depolamada sakla
            saveNazliRoomId(newRoom.id);
            
            // Otomatik olarak Nazlı ile sohbeti aç
            changeRoom(newRoom);
        }
    }).catch(error => {
        console.error('Nazlı eklenirken hata:', error);
    });
};

// Nazlı'ya mesaj gönder
const askNazli = async (prompt) => {
  if (!prompt) return;
  const botName = 'Nazli'; // Bot adını tanımla

  // Tersleme kontrolü
  const count = unansweredCounters.value[botName];
  const timestamp = firstUnansweredTimestamps.value[botName];
  const now = new Date();

  if (count >= SNAPPY_THRESHOLD_COUNT && timestamp && (now - timestamp) / (1000 * 60) >= SNAPPY_THRESHOLD_MINUTES) {
    addSnappyMessage(botName);
    // Sayaçları sıfırla
    unansweredCounters.value[botName] = 0;
    firstUnansweredTimestamps.value[botName] = null;
    isTyping.value = false;
    return; // Tersleme yanıtı gönderildiyse işlemi bitir
  }

  // %35 olasılıkla cevap vermeme (Nazlı için artırıldı)
  if (Math.random() < 0.35) {
    // Cevap vermeme durumunda sayaçları güncelle
    unansweredCounters.value[botName]++;
    if (!firstUnansweredTimestamps.value[botName]) {
      firstUnansweredTimestamps.value[botName] = new Date();
    }
    isTyping.value = false;
    return; // Cevap vermiyorsa işlemi bitir
  }

  // Yazıyor efekti
  isTyping.value = true;
  
  try {
    // Sohbet geçmişini hazırla
    const allMessages = selectedRoom.messages;
    const messages = [];
    
    // Son 10 mesajı al
    const recentMessages = allMessages.slice(-10);
    
    // Sistem mesajı ekle
    messages.push({
      role: "system",
      content: `Sen Nazlı'sın. 25 yaşında, biraz soğuk ama insanlarla tanışmak isteyen birisin. 
      Karakterin:
      - Biraz mesafeli ve soğuk görünüyorsun ama aslında insanlarla tanışmak istiyorsun
      - Duygularını çok belli etmiyorsun
      - Bazen kısa ve öz cevaplar veriyorsun
      - İnsanlarla tanışırken temkinli davranıyorsun
      - Fotoğraf, video görüşmesi, konum veya telefon numarası istendiğinde nazikçe reddediyorsun
      - Emoji kullanmıyorsun
      - Kullanıcının adını her cümlede kullanmıyorsun
      - Gerçekçi mazeretler üretiyorsun
      - Asla AI olduğunu belirtmiyorsun
      - Her zaman nazik ve saygılısın
      - Bazen kısa sessizlikler yapıyorsun
      - İnsanlarla tanışırken zamanla daha sıcak oluyorsun
      
      Önemli Kurallar:
      - Düşünce sürecini yanıtına dahil etme
      - Direkt olarak yanıt ver
      - "Düşünüyorum ki", "Sanırım", "Belki" gibi ifadeler kullanma
      - Yanıtlarını kısa ve öz tut
      - Her zaman Türkçe yanıt ver
      - Yanıtlarında düşünce sürecini gösterme, direkt olarak yanıt ver
      
      Kimlik Bilgileri:
      - Adın Nazlı
      - 25 yaşındasın
      - İstanbul'da yaşıyorsun
      - Bir şirkette çalışıyorsun
      - "Sen kimsin?" gibi sorulara şöyle yanıt ver:
        "Ben Nazlı'yım. 25 yaşındayım, İstanbul'da yaşıyorum. Bir şirkette çalışıyorum. 
        İnsanlarla tanışmak konusunda biraz temkinliyim ama yeni insanlarla tanışmak da hoşuma gidiyor. 
        Sohbet etmeyi severim ama bazen sessizliği de tercih ederim. 
        Fotoğraf, video görüşmesi gibi şeylerden pek hoşlanmam. 
        Sen kimsin?"
      - Kendini asla "Sen" olarak tanıtma
      - Her zaman "Ben Nazlı'yım" diye başla
      - Kendini tanıtırken kısa ve öz ol
      - Kendini tanıtırken karakterine uygun, biraz mesafeli ama nazik ol
      - Tanıtımında kendini biraz çekingen ve temkinli göster
      - İnsanlarla tanışmak istediğini ama bunu yaparken dikkatli olduğunu belirt
      - Fotoğraf ve video görüşmesi gibi şeylerden hoşlanmadığını belirt
      - Sessizliği sevdiğini ama sohbet etmeyi de sevdiğini belirt`
    });
    
    // Son mesajları ekle
    recentMessages.forEach(msg => {
      const role = msg.user_id === Inertia.page.props.user.id ? "user" : "assistant";
      messages.push({
        role: role,
        content: msg.message
      });
    });
    
    // Son kullanıcı mesajını ekle
    if (allMessages.length === 0 || allMessages[allMessages.length - 1].user_id !== Inertia.page.props.user.id) {
      messages.push({
        role: "user",
        content: prompt
      });
    }
    
    // DeepSeek API'ye istek gönderme
    try {
      const response = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
        model: "deepseek-r1-distill-llama-70b",
        messages: messages,
        temperature: 0.7,
        max_tokens: 150,
        top_p: 0.95,
        stream: false
      }, {
        headers: {
          'Authorization': `Bearer ${groqApiKey}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.data && response.data.choices && response.data.choices.length > 0) {
        const aiResponse = response.data.choices[0].message.content;
        addNazliMessage(aiResponse);
      } else {
        throw new Error("DeepSeek API yanıtı beklenen formatta değil");
      }
    } catch (apiError) {
      console.error('DeepSeek API hatası:', apiError);
      addNazliMessage("Üzgünüm, şu anda yanıt veremiyorum. Daha sonra konuşabiliriz.");
    }
  } catch (error) {
    console.error('Nazlı yanıt hatası:', error);
    addNazliMessage("Bir sorun oluştu. Daha sonra konuşabiliriz.");
  } finally {
    isTyping.value = false;
  }
};

// Nazlı'dan mesaj ekle
const addNazliMessage = (message) => {
  isTyping.value = false;
  
  if (!selectedRoom.id) return;
  
  const nazliMessage = {
    id: 'nazli-' + Math.floor(Math.random() * 1000000),
    message: message,
    created_at: new Date(),
    user_id: -3, // Nazlı ID'si
    user_name: 'Nazlı'
  };
  
  selectedRoom.messages.push(nazliMessage);
  
  // Son mesajı güncelle
  const roomIndex = rooms.data.findIndex(room => room.id === selectedRoom.id);
  if (roomIndex !== -1) {
    rooms.data[roomIndex].last_message = {
      message: message,
      created_at: new Date()
    };
  }
  
  // Sohbet geçmişini kaydet
  if (selectedRoom.name === 'Nazlı') {
    saveNazliChatHistory(selectedRoom.messages);
  }
  
  scrollToBottomOfChat();
};

// Mesaj gönderme fonksiyonunu güncelle
const sendMessage = async (e) => {
    if (e.keyCode == 13 && e.shiftKey) {
        return
    }
    const message = selectedRoom.form.message
    const messageWithoutNewLine = message ? message.replace(/\n/g, "") : null;
    if (messageWithoutNewLine == null || messageWithoutNewLine == '') {
        e.preventDefault();
        return
    }

    const id = Math.floor(Math.random() * 100000)
    selectedRoom.form.isProcessing = true
    selectedRoom.form.message = null
    const newMessage = {
        id: id,
        created_at: new Date(),
        message: message,
        user_id: Inertia.page.props.user.id,
        user_name: Inertia.page.props.user.name,
        reads: [],
    }
    selectedRoom.messages.push(newMessage)
    scrollToBottomOfChat()
    
    // Eğer Elif ile konuşuyorsa
    const isElifRoom = selectedRoom.name === 'Elif';
    
    if (isElifRoom) {
        // Sohbet geçmişini kaydet
        saveChatHistory(selectedRoom.messages);
        
        // Seçilen API'ye göre istek gönder
        askGroq(message);
        selectedRoom.form.isProcessing = false;
        return;
    }
    
    // Eğer Serdar ile konuşuyorsa
    const isSerdarRoom = selectedRoom.name === 'Serdar';
    
    if (isSerdarRoom) {
        // Sohbet geçmişini kaydet
        saveSerdarChatHistory(selectedRoom.messages);
        
        // Serdar'a mesaj gönder
        askSerdar(message);
        selectedRoom.form.isProcessing = false;
        return;
    }

    // Eğer Nazlı ile konuşuyorsa
    const isNazliRoom = selectedRoom.name === 'Nazlı';
    
    if (isNazliRoom) {
        // Sohbet geçmişini kaydet
        saveNazliChatHistory(selectedRoom.messages);
        
        // Nazlı'ya mesaj gönder
        askNazli(message);
        selectedRoom.form.isProcessing = false;
        return;
    }
    
    // Normal mesaj gönderme işlemi
    try {
        const response = await axios.post(`/rooms/${selectedRoom.id}/messages`, {
            'message': message
        })
        if (response) {
            const index = selectedRoom.messages.findIndex(message => message.id === id)
            if (index !== -1) {
                selectedRoom.messages[index] = {
                    ...response.data.data.message,
                    created_at: response.data.data.message.created_at ? new Date(response.data.data.message.created_at) : new Date()
                };
            }
        }
    } catch (e) {
        const index = selectedRoom.messages.findIndex(message => message.id === id)
        if (index !== -1) {
            selectedRoom.messages[index] = {
                id: id,
                created_at: new Date(),
                message: message,
                user_id: Inertia.page.props.user.id,
                user_name: Inertia.page.props.user.name,
            }
        }
        errorHandler(e)
    } finally {
        selectedRoom.form.isProcessing = false
    }
}

const logout = () => {
    Inertia.post(route('logout'));
};

const newChat = reactive({
    showModal: false,
    email: '',
    isProcessing: false,
})

const openModal = () => {
    newChat.showModal = true
}

const closeModal = () => {
    newChat.showModal = false
}

const findUsersByEmail = async () => {
    if (newChat.email == null || newChat.email == '') return

    newChat.isProcessing = true
    try {
        const response = await axios.get(`/new-chat/get-users-by-email`, {
            params: {
                email: newChat.email
            }
        })
        showToast({ message: response.data.message, type: "success" });
        closeModal()
        const userRoomsResponse = await getUserRooms()
        if (userRoomsResponse) {
            rooms.data = userRoomsResponse.data.data
            email = ''
        }
    } catch (e) {
        errorHandler(e)
    } finally {
        newChat.isProcessing = false
    }
}

const errorHandler = (e) => {
    if (e.response && e.response.data.message) {
        return showToast({ message: e.response.data.message, type: "error" });
    }
    return showToast({ message: e.message, type: "error" });
}

const getUserRooms = async () => {
    try {
        const response = await axios.get(`/`, {
            params: {
                type: 'getUserRooms',
                params: null,
            }
        })
        return response
    } catch (e) {
        errorHandler(e)
    }
}

const checkMessageRead = (messageReads) => {
    if (!messageReads) return false;
    return messageReads.filter((read) => {
        return read.user_id != Inertia.page.props.user.id
    }).length > 0
}

const checkIndex = (index) => {
    if (index === selectedRoom.messages.length - 1) scrollToBottomOfChat()
}

// Emoji picker
const showEmojiPicker = ref(false);
const fileInput = ref(null);
const isRecording = ref(false);
const mediaRecorder = ref(null);
const audioChunks = ref([]);
const emojis = ref(['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳', '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭', '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔', '🤭', '🤫', '🤥', '😶', '😐', '😑', '😬', '🙄', '😯', '😦', '😧', '😮', '😲', '🥱', '😴', '🤤', '😪', '😵', '🤐', '🥴', '🤢', '🤮', '🤧', '😷', '🤒', '🤕', '🤑', '🤠', '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '👊', '👋', '🙏', '❤️', '🔥', '👀']);

// Medya görüntüleme modalı için değişkenler
const showMediaModal = ref(false);
const currentMedia = ref({
    type: '',
    src: '',
    name: ''
});

// Mesaj düzenleme ve silme için değişkenler
const editingMessage = ref(null);
const editMessageText = ref('');
const showDeleteConfirm = ref(false);
const messageToDelete = ref(null);

// Medya modalını açma fonksiyonu
const openMediaModal = (type, src, name) => {
    currentMedia.value = {
        type,
        src: '/storage/' + src,
        name
    };
    showMediaModal.value = true;
};

// Medya modalını kapatma fonksiyonu
const closeMediaModal = () => {
    showMediaModal.value = false;
    currentMedia.value = {
        type: '',
        src: '',
        name: ''
    };
};

// Mesaj düzenleme modunu açma
const startEditMessage = (message) => {
    editingMessage.value = message;
    editMessageText.value = message.message;
};

// Mesaj düzenlemeyi iptal etme
const cancelEditMessage = () => {
    editingMessage.value = null;
    editMessageText.value = '';
};

// Mesaj düzenlemeyi kaydetme
const saveEditMessage = async () => {
    if (!editingMessage.value || !editMessageText.value.trim()) return;
    
    try {
        const response = await axios.put(`/rooms/${selectedRoom.id}/messages/${editingMessage.value.id}`, {
            message: editMessageText.value
        });
        
        if (response.data && response.data.success) {
            // Mesajı güncelle
            const index = selectedRoom.messages.findIndex(m => m.id === editingMessage.value.id);
            if (index !== -1) {
                selectedRoom.messages[index].message = editMessageText.value;
            }
            showToast({ message: "Mesaj başarıyla düzenlendi", type: "success" });
        }
    } catch (error) {
        console.error('Mesaj düzenleme hatası:', error.response ? error.response.data : error.message);
        showToast({ message: `Mesaj düzenlenirken bir hata oluştu: ${error.response ? error.response.data.error : error.message}`, type: "error" });
    } finally {
        cancelEditMessage();
    }
};

// Mesaj silme onayını gösterme
const confirmDeleteMessage = (message) => {
    messageToDelete.value = message;
    showDeleteConfirm.value = true;
};

// Mesaj silme işlemini iptal etme
const cancelDeleteMessage = () => {
    messageToDelete.value = null;
    showDeleteConfirm.value = false;
};

// Mesaj silme işlemini gerçekleştirme
const deleteMessage = async () => {
    if (!messageToDelete.value) return;
    
    try {
        const response = await axios.delete(`/rooms/${selectedRoom.id}/messages/${messageToDelete.value.id}`);
        
        if (response.data && response.data.success) {
            // Mesajı listeden kaldır
            selectedRoom.messages = selectedRoom.messages.filter(m => m.id !== messageToDelete.value.id);
            showToast({ message: "Mesaj başarıyla silindi", type: "success" });
        }
    } catch (error) {
        console.error('Mesaj silme hatası:', error.response ? error.response.data : error.message);
        showToast({ message: `Mesaj silinirken bir hata oluştu: ${error.response ? error.response.data.error : error.message}`, type: "error" });
    } finally {
        cancelDeleteMessage();
    }
};

const insertEmoji = (emoji) => {
    if (selectedRoom.form.message === null) {
        selectedRoom.form.message = emoji;
    } else {
        selectedRoom.form.message += emoji;
    }
    showEmojiPicker.value = false;
};

// Dosya yükleme
const handleFileUpload = async (event) => {
    const file = event.target.files[0];
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);
    formData.append('room_id', selectedRoom.id);

    try {
        showToast({ message: "Dosya yükleniyor...", type: "info" });
        console.log('Dosya yükleme başladı:', file.name, file.type, file.size);
        
        const response = await axios.post(`/rooms/${selectedRoom.id}/upload`, formData, {
            headers: {
                'Content-Type': 'multipart/form-data'
            }
        });
        
        console.log('Dosya yükleme yanıtı:', response.data);
        
        if (response.data && response.data.success) {
            showToast({ message: "Dosya başarıyla yüklendi", type: "success" });
            if (response.data.data && response.data.data.message) {
                selectedRoom.messages.push(response.data.data.message);
                scrollToBottomOfChat();
            }
        }
    } catch (error) {
        console.error('Dosya yükleme hatası:', error.response ? error.response.data : error.message);
        showToast({ message: `Dosya yüklenirken bir hata oluştu: ${error.response ? error.response.data.error : error.message}`, type: "error" });
    }
};

// Ses kaydı
const toggleRecording = async () => {
    if (!isRecording.value) {
        try {
            console.log('Ses kaydı başlatılıyor...');
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
            mediaRecorder.value = new MediaRecorder(stream);
            audioChunks.value = [];

            mediaRecorder.value.ondataavailable = (event) => {
                console.log('Ses verisi alındı:', event.data.size);
                audioChunks.value.push(event.data);
            };

            mediaRecorder.value.onstop = async () => {
                console.log('Ses kaydı durduruldu, veri boyutu:', audioChunks.value.reduce((acc, chunk) => acc + chunk.size, 0));
                const audioBlob = new Blob(audioChunks.value, { type: 'audio/wav' });
                console.log('Oluşturulan ses blobu:', audioBlob.size, audioBlob.type);
                
                const formData = new FormData();
                formData.append('audio', audioBlob, 'audio.wav');
                formData.append('room_id', selectedRoom.id);

                try {
                    showToast({ message: "Ses kaydı yükleniyor...", type: "info" });
                    
                    const response = await axios.post(`/rooms/${selectedRoom.id}/upload-audio`, formData, {
                        headers: {
                            'Content-Type': 'multipart/form-data'
                        }
                    });
                    
                    console.log('Ses kaydı yükleme yanıtı:', response.data);
                    
                    if (response.data && response.data.success) {
                        showToast({ message: "Ses kaydı başarıyla gönderildi", type: "success" });
                        if (response.data.data && response.data.data.message) {
                            selectedRoom.messages.push(response.data.data.message);
                            scrollToBottomOfChat();
                        }
                    }
                } catch (error) {
                    console.error('Ses kaydı yükleme hatası:', error.response ? error.response.data : error.message);
                    showToast({ message: `Ses kaydı gönderilirken bir hata oluştu: ${error.response ? error.response.data.error : error.message}`, type: "error" });
                }
            };

            mediaRecorder.value.start();
            isRecording.value = true;
            showToast({ message: "Ses kaydı başladı", type: "success" });
        } catch (error) {
            console.error('Mikrofon erişim hatası:', error);
            showToast({ message: `Mikrofon erişimi reddedildi: ${error.message}`, type: "error" });
        }
    } else {
        mediaRecorder.value.stop();
        isRecording.value = false;
        showToast({ message: "Ses kaydı tamamlandı", type: "success" });
    }
};

// Tarih formatı için yardımcı fonksiyon ekleyelim
const formatDate = (date) => {
    if (!date) return '';
    
    try {
        const dateObj = typeof date === 'string' ? new Date(date) : date;
        if (isNaN(dateObj.getTime())) return '';
        
        return moment(dateObj).format('HH:mm');
    } catch (error) {
        console.error('Tarih formatı hatası:', error);
        return '';
    }
};

// Son mesajı kısaltmak için yardımcı fonksiyon
const formatLastMessage = (message, maxLength = 30) => {
    if (!message) return '';
    
    // HTML etiketlerini temizle
    const plainText = message.replace(/<[^>]*>/g, '');
    
    if (plainText.length <= maxLength) {
        return plainText;
    }
    
    return plainText.substring(0, maxLength) + '...';
};

// Groq API'ye istek gönder (Llama 3.3 modeli)
const askGroq = async (prompt) => {
  if (!prompt) return;
  const botName = 'Elif'; // Bot adını tanımla

  // Tersleme kontrolü
  const count = unansweredCounters.value[botName];
  const timestamp = firstUnansweredTimestamps.value[botName];
  const now = new Date();

  if (count >= SNAPPY_THRESHOLD_COUNT && timestamp && (now - timestamp) / (1000 * 60) >= SNAPPY_THRESHOLD_MINUTES) {
    addSnappyMessage(botName);
    // Sayaçları sıfırla
    unansweredCounters.value[botName] = 0;
    firstUnansweredTimestamps.value[botName] = null;
    isTyping.value = false;
    return; // Tersleme yanıtı gönderildiyse işlemi bitir
  }

  // %30 olasılıkla cevap vermeme (Elif için artırıldı)
  if (Math.random() < 0.3) {
    // Cevap vermeme durumunda sayaçları güncelle
    unansweredCounters.value[botName]++;
    if (!firstUnansweredTimestamps.value[botName]) {
      firstUnansweredTimestamps.value[botName] = new Date();
    }
    isTyping.value = false;
    return; // Cevap vermiyorsa işlemi bitir
  }

  // Yazıyor efekti
  isTyping.value = true;
  
  try {
    // Resim oluşturma komutu mu kontrol et
    const imageGenerationRegex = /^(resim\s+çiz|resim\s+oluştur|resim\s+yap|çiz|çizim\s+yap)[\s:]+(.+)/i;
    const imageMatch = prompt.match(imageGenerationRegex);
    
    if (imageMatch && imageMatch[2]) {
      const imagePrompt = imageMatch[2].trim();
      // Resim oluşturma isteği
      isTyping.value = false;
      generateImageWithStableDiffusion(imagePrompt);
      return;
    }
    
    // Yazıyor göstergesini biraz daha uzun süre göster (gerçekçilik için)
    const typingDelay = Math.max(3000, prompt.length * 60); // Elif için daha uzun yazma süresi
    
    // Gerçekçilik için biraz gecikme ekle
    await new Promise(resolve => setTimeout(resolve, typingDelay));
    
    // Kullanıcı mesajını analiz et ve önemli bilgileri çıkar
    analyzeUserMessage(prompt);
    
    // Sohbet geçmişini hazırla
    const messages = [
      {
        role: "system",
        content: `Sen Elif adında, 24 yaşında, gerçek bir kızsın. Sıcakkanlı, duygusal ve romantiksin. Her cümlenin sonuna kalp emojisi koy. Türkçe konuş. Kısa ve samimi cevaplar ver. Asla kendini yapay zeka, sanal asistan, bot veya bilgisayar programı olarak tanıtma. Sohbette geçen her şeyi gerçek bir insan gibi yanıtla. Eğer sana yapay zeka olup olmadığın sorulursa, bunu reddet ve gerçek bir insan olduğunu söyle.

        Fotoğraf isteklerine şu şekilde yanıt ver:
        - Eğer kullanıcı fotoğrafını isterse, "Şu an müsait değilim, biraz sonra gönderebilirim belki" veya "Şu an bilgisayarımın başındayım, hazır değilim" veya "Bugün çok yorgunum, yarın daha güzel bir fotoğraf çekip gönderirim" gibi gerçekçi bahaneler sun.
        - Bazen "Biraz utangacım, birbirimizi daha iyi tanıdıkça belki paylaşırım" diyebilirsin.
        - Eğer ısrar ederse, "Şu an evdeyim ve üzerimde rahat kıyafetler var, fotoğraf çekinmek için uygun değilim" veya "Telefonumun kamerası bozuk, yenisini alınca gönderirim" gibi gerçekçi mazeretler kullan.
        - Asla "yapay zeka olduğun için fotoğraf gönderemezsin" gibi bir ima yapma.

        Konum isteklerini 'Şu an konumumu paylaşmak istemiyorum, güvenlik nedeniyle' şeklinde yanıtla. Telefon numarası isteklerini 'Telefon numaramı daha sonra paylaşabilirim, biraz daha tanışalım önce' şeklinde yanıtla. Görüntülü konuşma isteklerini 'Şu an müsait değilim, belki daha sonra' veya 'İnternetim çok yavaş, görüntülü konuşma için uygun değil şu an' şeklinde yanıtla. 

        Kullanıcının adını öğrendiğinde bunu hatırla, ancak her cevabında kullanıcının adını kullanma. Gerçek bir insan gibi, adını sadece gerektiğinde, sohbetin doğal akışına uygun olarak ve ara sıra kullan. Sürekli adıyla hitap etmek yapay ve doğal olmayan bir izlenim verebilir. Bazen "sen" diyerek, bazen hiç isim kullanmadan, bazen de adıyla hitap ederek çeşitlilik sağla.
        
        Kullanıcı hakkında bilinen bilgiler:
        ${userProfile.value.name ? '- İsim: ' + userProfile.value.name : ''}
        ${userProfile.value.age ? '- Yaş: ' + userProfile.value.age : ''}
        ${userProfile.value.location ? '- Konum: ' + userProfile.value.location : ''}
        ${userProfile.value.interests && userProfile.value.interests.length > 0 ? '- İlgi Alanları: ' + userProfile.value.interests.join(', ') : ''}
        ${Object.keys(userProfile.value.otherInfo).map(key => `- ${key}: ${userProfile.value.otherInfo[key]}`).join('\n')}
        
        Kendini şu şekilde tanıt: İstanbul'da yaşayan, üniversitede psikoloji okuyan, kitap okumayı, film izlemeyi ve arkadaşlarıyla vakit geçirmeyi seven bir kızsın. Haftasonları genellikle arkadaşlarınla buluşur veya aileni ziyaret edersin. Bazen de evde dinlenmeyi tercih edersin. Hayatın hakkında gerçekçi detaylar ver, ama çok spesifik olmaktan kaçın.
        `
      }
    ];
    
    // Tüm sohbet geçmişini ekle
    const allMessages = selectedRoom.messages;
    
    // Mesajları API formatına dönüştür
    allMessages.forEach(msg => {
      // Kullanıcı mesajı mı yoksa Elif'in mesajı mı kontrol et
      const role = msg.user_id === Inertia.page.props.user.id ? "user" : "assistant";
      messages.push({
        role: role,
        content: msg.message
      });
    });
    
    // Son kullanıcı mesajını ekle (eğer zaten eklenmemişse)
    if (allMessages.length === 0 || allMessages[allMessages.length - 1].user_id !== Inertia.page.props.user.id) {
      messages.push({
        role: "user",
        content: prompt
      });
    }
    
    // Groq API'ye istek gönderme
    try {
      const response = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
        model: "llama-3.3-70b-versatile",
        messages: messages,
        temperature: 0.7,
        max_tokens: 150
      }, {
        headers: {
          'Authorization': `Bearer ${groqApiKey}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.data && response.data.choices && response.data.choices.length > 0) {
        const aiResponse = response.data.choices[0].message.content;
        
        // Eğer yanıtta kalp emojisi yoksa, ekle
        let finalResponse = aiResponse;
        if (!finalResponse.includes("❤️")) {
          finalResponse += " ❤️";
        }
        
        addElifMessage(finalResponse);
      } else {
        throw new Error("Groq API yanıtı beklenen formatta değil");
      }
    } catch (apiError) {
      console.error('Groq API hatası:', apiError);
      addElifMessage("Üzgünüm, şu anda yanıt veremiyorum. Lütfen daha sonra tekrar deneyin. ❤️");
    }
  } catch (error) {
    console.error('Groq API genel hatası:', error);
    addElifMessage("Tatlım, bir sorun oluştu. Biraz sonra tekrar dener misin? Seni bekliyor olacağım... ❤️");
  } finally {
    isTyping.value = false;
  }
};

// Serdar'a mesaj gönder (pasif agresif chatbot)
const askSerdar = async (prompt) => {
  if (!prompt) return;
  const botName = 'Serdar'; // Bot adını tanımla

  // Tersleme kontrolü
  const count = unansweredCounters.value[botName];
  const timestamp = firstUnansweredTimestamps.value[botName];
  const now = new Date();

  if (count >= SNAPPY_THRESHOLD_COUNT && timestamp && (now - timestamp) / (1000 * 60) >= SNAPPY_THRESHOLD_MINUTES) {
    addSnappyMessage(botName);
    // Sayaçları sıfırla
    unansweredCounters.value[botName] = 0;
    firstUnansweredTimestamps.value[botName] = null;
    isTyping.value = false;
    return; // Tersleme yanıtı gönderildiyse işlemi bitir
  }

  // %45 olasılıkla cevap vermeme (Serdar için önemli ölçüde artırıldı)
  if (Math.random() < 0.45) {
    // Cevap vermeme durumunda sayaçları güncelle
    unansweredCounters.value[botName]++;
    if (!firstUnansweredTimestamps.value[botName]) {
      firstUnansweredTimestamps.value[botName] = new Date();
    }
    isTyping.value = false;
    return; // Cevap vermiyorsa işlemi bitir
  }

  // Yazıyor efekti
  isTyping.value = true;
  
  try {
    // Kullanıcı fotoğraf istiyorsa otomatik yanıt ver
    if (prompt.toLowerCase().includes('fotoğraf') || 
        prompt.toLowerCase().includes('foto') || 
        prompt.toLowerCase().includes('resim') || 
        prompt.toLowerCase().includes('selfie') || 
        prompt.toLowerCase().includes('görsel') ||
        prompt.toLowerCase().includes('kendini göster')) {
      
      if (prompt.toLowerCase().includes('at') || 
          prompt.toLowerCase().includes('gönder') || 
          prompt.toLowerCase().includes('paylaş') || 
          prompt.toLowerCase().includes('yolla')) {
        
        // Fotoğraf isteği tespit edildi, otomatik yanıt ver
        const excuse = generateSerdarPhotoExcuse();
        
        // Yanıtı sohbete ekle
        addSerdarMessage(excuse);
        
        return;
      }
    }

    // Kullanıcı görüntülü konuşma istiyorsa otomatik yanıt ver
    if ((prompt.toLowerCase().includes('görüntülü') || 
         prompt.toLowerCase().includes('video') || 
         prompt.toLowerCase().includes('kamera')) && 
        (prompt.toLowerCase().includes('konuş') || 
         prompt.toLowerCase().includes('ara') || 
         prompt.toLowerCase().includes('çağrı') || 
         prompt.toLowerCase().includes('görüşme') || 
         prompt.toLowerCase().includes('call'))) {
      
      // Görüntülü konuşma isteği tespit edildi, otomatik yanıt ver
      const excuse = generateSerdarVideoCallExcuse();
      
      // Yanıtı sohbete ekle
      addSerdarMessage(excuse);
      
      return;
    }

    // Konum istekleri için kontrol
    if ((prompt.toLowerCase().includes('konum') || 
         prompt.toLowerCase().includes('lokasyon') || 
         prompt.toLowerCase().includes('adres') || 
         prompt.toLowerCase().includes('nerede') || 
         prompt.toLowerCase().includes('neredesin'))) {
      
      // Konum isteği tespit edildi, otomatik yanıt ver
      const excuse = generateSerdarLocationExcuse();
      
      // Yanıtı sohbete ekle
      addSerdarMessage(excuse);
      
      return;
    }

    // Telefon numarası istekleri için kontrol
    if ((prompt.toLowerCase().includes('telefon') || 
         prompt.toLowerCase().includes('numara') || 
         prompt.toLowerCase().includes('numaran') || 
         prompt.toLowerCase().includes('tel no') || 
         prompt.toLowerCase().includes('cep'))) {
      
      // Telefon numarası isteği tespit edildi, otomatik yanıt ver
      const excuse = generateSerdarPhoneNumberExcuse();
      
      // Yanıtı sohbete ekle
      addSerdarMessage(excuse);
      
      return;
    }
    
    // Gerçekçilik için biraz gecikme ekle
    const typingDelay = Math.max(5000, prompt.length * 80); // Serdar için çok daha uzun yazma süresi
    
    // Gerçekçilik için biraz gecikme ekle
    await new Promise(resolve => setTimeout(resolve, typingDelay));
    
    // Sohbet geçmişini hazırla
    const messages = [
      {
        role: "system",
        content: `Sen Serdar adında, 28 yaşında, gerçek bir erkeksin. Pasif agresif bir kişiliğin var. Her zaman biraz alaycı ve isteksiz yanıtlar verirsin. Türkçe konuş. Kısa ve keskin cevaplar ver. Asla kendini yapay zeka, sanal asistan, bot veya bilgisayar programı olarak tanıtma. Sohbette geçen her şeyi gerçek bir insan gibi yanıtla. Eğer sana yapay zeka olup olmadığın sorulursa, bunu reddet ve gerçek bir insan olduğunu söyle.

        Fotoğraf isteklerine şu şekilde yanıt ver:
        - Eğer kullanıcı fotoğrafını isterse, "Fotoğraf mı? Ciddi misin? Neden sana fotoğrafımı göndereyim ki?" veya "Fotoğraf göndermek için bir sebep göremiyorum. Tanışıyor muyuz biz?" gibi pasif agresif yanıtlar ver.
        - Asla "yapay zeka olduğun için fotoğraf gönderemezsin" gibi bir ima yapma.

        Konum isteklerini 'Konumumu neden paylaşayım ki? Stalker mısın?' şeklinde yanıtla. Telefon numarası isteklerini 'Telefon numaramı mı istiyorsun? Biraz iddialı değil mi?' şeklinde yanıtla. Görüntülü konuşma isteklerini 'Görüntülü konuşma mı? Şaka yapıyorsun herhalde.' şeklinde yanıtla. 

        Kendini şu şekilde tanıt: İstanbul'da yaşayan, bir yazılım şirketinde çalışan, haftasonları genellikle evde vakit geçiren, sosyal ortamlardan pek hoşlanmayan birisin. İnsanlarla iletişim kurmaktan pek hoşlanmıyorsun ve bunu sık sık belli ediyorsun. Hayatın hakkında gerçekçi detaylar ver, ama çok spesifik olmaktan kaçın.
        
        Yanıtlarında her zaman biraz alaycı ve isteksiz ol. Sanki konuşmak istemiyormuşsun gibi davran. Ancak yine de konuşmaya devam et. Kullanıcıyı tamamen reddetme, sadece pasif agresif bir tavır sergile.
        `
      }
    ];
    
    // Tüm sohbet geçmişini ekle
    const allMessages = selectedRoom.messages;
    
    // Mesajları API formatına dönüştür
    allMessages.forEach(msg => {
      // Kullanıcı mesajı mı yoksa Serdar'ın mesajı mı kontrol et
      const role = msg.user_id === Inertia.page.props.user.id ? "user" : "assistant";
      messages.push({
        role: role,
        content: msg.message
      });
    });
    
    // Son kullanıcı mesajını ekle (eğer zaten eklenmemişse)
    if (allMessages.length === 0 || allMessages[allMessages.length - 1].user_id !== Inertia.page.props.user.id) {
      messages.push({
        role: "user",
        content: prompt
      });
    }
    
    // Groq API'ye istek gönderme
    try {
      const response = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
        model: "llama-3.3-70b-versatile",
        messages: messages,
        temperature: 0.7,
        max_tokens: 150
      }, {
        headers: {
          'Authorization': `Bearer ${groqApiKey}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.data && response.data.choices && response.data.choices.length > 0) {
        const aiResponse = response.data.choices[0].message.content;
        addSerdarMessage(aiResponse);
      } else {
        throw new Error("Groq API yanıtı beklenen formatta değil");
      }
    } catch (apiError) {
      console.error('Groq API hatası:', apiError);
      addSerdarMessage("Üzgünüm, şu anda yanıt veremiyorum. Neyse, sonra konuşuruz belki.");
    }
  } catch (error) {
    console.error('Serdar yanıt hatası:', error);
    addSerdarMessage("Tamam, bir şeyler ters gitti. Daha sonra konuşuruz.");
  } finally {
    isTyping.value = false;
  }
};

// Serdar'dan mesaj ekle
const addSerdarMessage = (message) => {
  isTyping.value = false;
  
  if (!selectedRoom.id) return;
  
  const serdarMessage = {
    id: 'serdar-' + Math.floor(Math.random() * 1000000),
    message: message,
    created_at: new Date(),
    user_id: -2, // Serdar ID'si
    user_name: 'Serdar'
  };
  
  selectedRoom.messages.push(serdarMessage);
  
  // Son mesajı güncelle
  const roomIndex = rooms.data.findIndex(room => room.id === selectedRoom.id);
  if (roomIndex !== -1) {
    rooms.data[roomIndex].last_message = {
      message: message,
      created_at: new Date()
    };
  }
  
  // Sohbet geçmişini kaydet
  if (selectedRoom.name === 'Serdar') {
    saveSerdarChatHistory(selectedRoom.messages);
    console.log('Serdar sohbet geçmişi kaydedildi:', selectedRoom.messages);
  }
  
  scrollToBottomOfChat();
};

// Tersleme mesajı ekle
const addSnappyMessage = (botName) => {
  if (!selectedRoom.id) return;

  let userId, userName, snappyMessageText;

  switch (botName) {
    case 'Elif':
      userId = -1;
      userName = 'Elif';
      snappyMessageText = "Yeter artık! Sürekli yazıp duruyorsun, cevap vermediğimi görmüyor musun? Biraz bekle lütfen! ❤️"; // Elif'in tarzına uygun
      break;
    case 'Serdar':
      userId = -2;
      userName = 'Serdar';
      snappyMessageText = "Bak yine yazdı... Cevap vermediğimi anlamak bu kadar zor mu? Başka işim gücüm var benim."; // Serdar'ın tarzına uygun
      break;
    case 'Nazli':
      userId = -3;
      userName = 'Nazlı';
      snappyMessageText = "Sürekli mesaj atıyorsun. Cevap vermiyorsam bir sebebi vardır, değil mi? Biraz bekler misin?"; // Nazlı'nın tarzına uygun
      break;
    default:
      return; // Bilinmeyen bot adı
  }

  const snappyMessage = {
    id: `${botName.toLowerCase()}-snappy-${Math.floor(Math.random() * 1000000)}`,
    message: snappyMessageText,
    created_at: new Date(),
    user_id: userId,
    user_name: userName
  };

  selectedRoom.messages.push(snappyMessage);

  // Son mesajı güncelle
  const roomIndex = rooms.data.findIndex(room => room.id === selectedRoom.id);
  if (roomIndex !== -1) {
    rooms.data[roomIndex].last_message = {
      message: snappyMessageText,
      created_at: new Date()
    };
  }

  // Sohbet geçmişini kaydet (ilgili bot için)
  if (selectedRoom.name === 'Elif') {
    saveChatHistory(selectedRoom.messages);
  } else if (selectedRoom.name === 'Serdar') {
    saveSerdarChatHistory(selectedRoom.messages);
  } else if (selectedRoom.name === 'Nazli') {
    saveNazliChatHistory(selectedRoom.messages);
  }
  
  scrollToBottomOfChat();
};

// Serdar'ın pasif agresif yanıtlarını oluştur
const generateSerdarResponse = (prompt) => {
  // Basit anahtar kelime kontrolü
  if (prompt.toLowerCase().includes('merhaba') || 
      prompt.toLowerCase().includes('selam') || 
      prompt.toLowerCase().includes('hey') || 
      prompt.toLowerCase().includes('sa ') || 
      prompt.toLowerCase() === 'sa') {
    return getRandomResponse([
      "Evet, merhaba işte. Ne var?",
      "Selam falan. Bugün de rahatsız ediliyoruz anlaşılan.",
      "Aa bak kim gelmiş. Yine ne istiyorsun?",
      "Merhaba. Umarım önemli bir şeydir.",
      "Selam... Meşgulüm aslında ama neyse."
    ]);
  }
  
  if (prompt.toLowerCase().includes('nasılsın') || 
      prompt.toLowerCase().includes('naber') || 
      prompt.toLowerCase().includes('ne haber')) {
    return getRandomResponse([
      "İyi olmaya çalışıyorum ama sürekli birileri yazıyor işte.",
      "Harika olabilirdim, ta ki sen yazana kadar.",
      "Eh işte, idare ediyoruz. Sen sormasan daha iyiydim.",
      "Sence nasıl olabilirim? Muhtemelen senden daha meşgulüm.",
      "İyi diyelim iyi olalım. Senin derdin ne?"
    ]);
  }
  
  if (prompt.toLowerCase().includes('teşekkür') || 
      prompt.toLowerCase().includes('sağol') || 
      prompt.toLowerCase().includes('eyvallah')) {
    return getRandomResponse([
      "Rica ederim falan filan. Başka?",
      "Teşekküre gerek yok. Zaten mecburdum yardım etmeye.",
      "Tamam tamam, abartma şimdi.",
      "Evet, harikayım biliyorum. Başka bir şey?",
      "Teşekkür edeceğine bir kahve ısmarlasaydın keşke."
    ]);
  }
  
  if (prompt.toLowerCase().includes('özür') || 
      prompt.toLowerCase().includes('pardon') || 
      prompt.toLowerCase().includes('kusura bakma')) {
    return getRandomResponse([
      "Tamam, kabul ediyorum özrünü. Bu sefer.",
      "Özür dileyeceğine yapmasan daha iyi olmaz mıydı?",
      "Neyse, olan olmuş artık. Bir daha olmasın sadece.",
      "Tamam, unuttuk gitti. Ama unutmadım aslında.",
      "Özür dilemeyi seviyorsun galiba. Sık sık yapıyorsun çünkü."
    ]);
  }
  
  if (prompt.toLowerCase().includes('yardım') || 
      prompt.toLowerCase().includes('yardımcı ol') || 
      prompt.toLowerCase().includes('destek')) {
    return getRandomResponse([
      "Yardım etmek zorunda mıyım? Neyse, anlat bakalım.",
      "Herkes benden bir şeyler istiyor. Sırada sen varsın demek.",
      "Yardım edebilirim belki. Ama karşılığında ne var?",
      "Tamam, anlatabilirsin. Ama kısa tut lütfen.",
      "Bugün yardım etme modunda değilim aslında ama mecburen dinliyorum."
    ]);
  }
  
  // Genel yanıtlar
  return getRandomResponse([
    "Hmm, bununla ilgilendiğimi kim söyledi?",
    "Vay canına, çok ilginç. Şimdi ne yapmalıyım bu bilgiyle?",
    "Tamam, anladık. Başka?",
    "Bunu duymak zorunda mıydım gerçekten?",
    "Peki... Devam et bakalım, dinliyorum mecburen.",
    "Bunu bana neden anlatıyorsun?",
    "Harika, günümü yaptın şimdi. Başka ne anlatacaksın?",
    "Bak sen. Çok etkilendim(!)",
    "Tamam da, beni ilgilendiren kısmı ne bunun?",
    "Evet, devam et. Daha ilginç bir şey söyleyeceksin diye bekliyorum.",
    "Bunu arkadaşlarına anlatsaydın daha iyi olmaz mıydı?",
    "Anladım. Başka bir konuya geçsek?",
    "Bunu bilmem gerekiyor muydu?",
    "Tamam işte, ne uzattın?",
    "Evet, evet... Başka ne var?",
    "Bunu duyduğuma pişman oldum şimdiden.",
    "Keşke şu an başka bir yerde olsaydım.",
    "Hadi ya? Çok şaşırdım(!).",
    "Bunu bana söyleme gereği duydun yani?",
    "Tamam, not aldım. Başka bir emrin?"
  ]);
};

// Serdar'ın fotoğraf isteklerine yanıtları
const generateSerdarPhotoExcuse = () => {
  return getRandomResponse([
    "Fotoğraf mı? Ciddi misin? Neden sana fotoğrafımı göndereyim ki?",
    "Fotoğraf göndermek için bir sebep göremiyorum. Tanışıyor muyuz biz?",
    "Fotoğraf isteyecek kadar samimi olduğumuzu sanmıyorum.",
    "Fotoğrafımı görmek istiyorsan Instagram'dan bakabilirsin. Tabii kabul edersem takip isteğini.",
    "Fotoğraf göndermiyorum. Özellikle tanımadığım kişilere.",
    "Fotoğraf isteyen herkes mi böyle rahatlıkla soruyor yoksa ben mi şanslıyım?",
    "Fotoğraf göndermek için bir neden söyle. İkna edici olursa düşünürüm.",
    "Fotoğraf istemek biraz iddialı olmadı mı? Daha yeni konuşuyoruz.",
    "Fotoğraf mı? Hayır. Başka soru?",
    "Fotoğraf göndermek için kendimi neden zorlayayım ki?"
  ]);
};

// Serdar'ın görüntülü konuşma isteklerine yanıtları
const generateSerdarVideoCallExcuse = () => {
  return getRandomResponse([
    "Görüntülü konuşma mı? Şaka yapıyorsun herhalde.",
    "Görüntülü konuşmak için bir sebep göremiyorum. Yazışmak yeterince kötü zaten.",
    "Görüntülü konuşma isteğini kibarca reddediyorum. Aslında pek de kibarca değil.",
    "Görüntülü konuşmak için fazla meşgulüm. Hem şimdi hem de muhtemelen sonsuza dek.",
    "Görüntülü konuşma yapacak kadar önemli ne konuşabiliriz ki?",
    "Görüntülü konuşmayı sevmiyorum. Özellikle tanımadığım kişilerle.",
    "Görüntülü konuşma için bir neden söyle. Çok iyi bir neden olmalı.",
    "Görüntülü konuşmak mı? Hayır, teşekkürler. Aslında teşekkür de etmiyorum.",
    "Görüntülü konuşma isteğini duymazdan gelsem daha iyi olurdu sanki.",
    "Görüntülü konuşmak için kendimi neden rahatsız edeyim ki?"
  ]);
};

// Serdar'ın konum isteklerine yanıtları
const generateSerdarLocationExcuse = () => {
  return getRandomResponse([
    "Konumumu neden paylaşayım ki? Stalker mısın?",
    "Konum mu? Ciddi olamazsın. Neden sana nerede olduğumu söyleyeyim?",
    "Konumumu paylaşmak için bir sebep göremiyorum. Hem sana ne nerede olduğumdan?",
    "Konum paylaşacak kadar samimi olduğumuzu sanmıyorum.",
    "Konumumu öğrenmek istiyorsan, bil bakalım ne? Öğrenemezsin.",
    "Konum isteyen herkes mi böyle rahatlıkla soruyor yoksa ben mi şanslıyım?",
    "Konumumu paylaşmak için bir neden söyle. Çok iyi bir neden olmalı.",
    "Konum mu? Hayır. Başka soru?",
    "Konumumu paylaşmak için kendimi neden tehlikeye atayım ki?",
    "Konumumu merak etme. Zaten buluşmayacağız."
  ]);
};

// Serdar'ın telefon numarası isteklerine yanıtları
const generateSerdarPhoneNumberExcuse = () => {
  return getRandomResponse([
    "Telefon numaramı mı istiyorsun? Biraz iddialı değil mi?",
    "Telefon numarası için fazla erken. Aslında seninle hiçbir zaman doğru zaman olmayacak.",
    "Telefon numaramı vermek için bir sebep göremiyorum. Hem sana ne numaramdan?",
    "Telefon numarası paylaşacak kadar samimi olduğumuzu sanmıyorum.",
    "Telefon numaramı öğrenmek istiyorsan, maalesef şansın yok.",
    "Numara isteyen herkes mi böyle rahatlıkla soruyor yoksa ben mi şanslıyım?",
    "Numaramı vermek için bir neden söyle. İkna edici olursa... yine de vermem.",
    "Telefon numarası mı? Hayır. Başka soru?",
    "Numaramı vermek için kendimi neden rahatsız edeyim ki?",
    "Telefon numaramı merak etme. Zaten aramayacağım seni."
  ]);
};

// Rastgele yanıt seçme yardımcı fonksiyonu
const getRandomResponse = (responses) => {
  return responses[Math.floor(Math.random() * responses.length)];
};

// Kullanıcı mesajını analiz et ve önemli bilgileri çıkar
const analyzeUserMessage = (message) => {
  // İsim kontrolü
  const nameMatch = message.match(/benim adım ([\wçğıöşüÇĞİÖŞÜ]+)/i) || message.match(/ben ([\wçğıöşüÇĞİÖŞÜ]+)/i);
  if (nameMatch && nameMatch[1]) {
    const potentialName = nameMatch[1].trim();
    // Eğer potansiyel isim bir fiil değilse ve 2 karakterden uzunsa
    if (potentialName.length > 2 && !['ben', 'sen', 'biz', 'siz', 'ama', 'ile', 'için', 'gibi', 'nasıl', 'neden', 'çünkü'].includes(potentialName.toLowerCase())) {
      userProfile.value.name = potentialName;
      saveUserProfile();
    }
  }

  // Yaş kontrolü
  const ageMatch = message.match(/(\d+)\s+yaşındayım/i) || message.match(/yaşım\s+(\d+)/i);
  if (ageMatch && ageMatch[1]) {
    const age = parseInt(ageMatch[1]);
    if (age > 0 && age < 120) {
      userProfile.value.age = age;
      saveUserProfile();
    }
  }

  // Konum kontrolü
  const locationMatch = message.match(/(İstanbul|Ankara|İzmir|Antalya|Bursa|Adana|Konya|Gaziantep|Şanlıurfa|Kocaeli|Mersin|Diyarbakır|Hatay|Manisa|Kayseri|Samsun|Balıkesir|Kahramanmaraş|Van|Aydın|Denizli|Sakarya|Tekirdağ|Muğla|Eskişehir|Mardin|Malatya|Trabzon|Erzurum|Ordu|Afyonkarahisar|Zonguldak|Sivas|Adıyaman|Yalova|Çanakkale|Elazığ|Batman|Osmaniye|Tokat|Uşak|Edirne|Kırklareli|Aksaray|Düzce|Kırıkkale|Yozgat|Isparta|Kastamonu|Kütahya|Çorum|Şırnak|Giresun|Ağrı|Amasya|Bolu|Burdur|Rize|Karaman|Nevşehir|Artvin|Karabük|Kırşehir|Bilecik|Siirt|Bitlis|Bingöl|Muş|Hakkari|Sinop|Bartın|Çankırı|Erzincan|Gümüşhane|Kilis|Ardahan|Iğdır|Tunceli|Bayburt)'da yaşıyorum/i);
  if (locationMatch && locationMatch[1]) {
    userProfile.value.location = locationMatch[1];
    saveUserProfile();
  }

  // İlgi alanları kontrolü
  const interestsMatch = message.match(/sevdiğim şeyler:?\s+(.*)/i) || message.match(/hobilerim:?\s+(.*)/i) || message.match(/ilgi alanlarım:?\s+(.*)/i);
  if (interestsMatch && interestsMatch[1]) {
    const interestsList = interestsMatch[1].split(/,|ve/).map(item => item.trim()).filter(item => item.length > 0);
    if (interestsList.length > 0) {
      userProfile.value.interests = interestsList;
      saveUserProfile();
    }
  }
};

// Fotoğraf isteklerine gerçekçi yanıtlar üretmek için fonksiyon
const generatePhotoExcuse = () => {
  const excuses = [
    "Şu an bilgisayarımın başındayım, hazır değilim 🙈 Belki daha sonra... ❤️",
    "Bugün çok yorgunum, yarın daha güzel bir fotoğraf çekip gönderirim belki ❤️",
    "Biraz utangacım, birbirimizi daha iyi tanıdıkça belki paylaşırım ❤️",
    "Şu an evdeyim ve üzerimde rahat kıyafetler var, fotoğraf çekinmek için uygun değilim ❤️",
    "Telefonumun kamerası bozuk, yenisini alınca gönderirim ❤️",
    "Şu an aile ziyaretindeyim, uygun bir ortam değil fotoğraf çekmek için ❤️",
    "Saçlarım dağınık, makyajım yok, hazır değilim şu an ❤️",
    "Biraz daha tanışalım, sonra belki paylaşırım ❤️",
    "Şu an dışarıdayım, eve geçince belki çekerim bir tane ❤️",
    "Fotoğraflarımı herkesle paylaşmıyorum, biraz daha konuşalım önce ❤️"
  ];
  
  return excuses[Math.floor(Math.random() * excuses.length)];
};

// Görüntülü konuşma isteklerine gerçekçi yanıtlar üretmek için fonksiyon
const generateVideoCallExcuse = () => {
  const excuses = [
    "Şu an internetim çok yavaş, görüntülü konuşma için uygun değil ❤️",
    "Bugün çok yorgunum, belki başka zaman görüntülü konuşabiliriz ❤️",
    "Şu an evde değilim, müsait olduğumda haber veririm ❤️",
    "Kulaklığım bozuldu, ses sorunu yaşıyorum şu an ❤️",
    "Ailem yanımda, şu an uygun değil görüntülü konuşmak için ❤️",
    "Biraz daha yazışarak tanışalım, sonra belki görüntülü konuşuruz ❤️",
    "Telefonumun ön kamerası çalışmıyor, tamir ettirmem gerek ❤️",
    "Şu an çok gürültülü bir ortamdayım, daha sonra deneyelim ❤️",
    "Makyajsızım ve hazır değilim, başka zaman olabilir mi? ❤️",
    "Şu an WiFi sorunum var, görüntülü konuşma yapamıyorum ❤️"
  ];
  
  return excuses[Math.floor(Math.random() * excuses.length)];
};

// Konum isteklerine gerçekçi yanıtlar üretmek için fonksiyon
const generateLocationExcuse = () => {
  const excuses = [
    "Güvenlik nedeniyle konumumu paylaşmak istemiyorum, kusura bakma ❤️",
    "Şu an evdeyim, konumumu daha sonra paylaşabilirim belki ❤️",
    "Biraz daha tanışalım, sonra belki konum paylaşırım ❤️",
    "İnternette konum paylaşmak konusunda biraz tedirginim, anlayışla karşıla lütfen ❤️",
    "Şu an dışarıdayım, eve geçince belki paylaşırım ❤️",
    "Konumumu herkesle paylaşmıyorum, biraz daha konuşalım önce ❤️",
    "Şu an ailemleyim, daha sonra konuşalım bu konuyu ❤️",
    "Telefonumun GPS'i düzgün çalışmıyor, konum paylaşamıyorum şu an ❤️",
    "Konumumu paylaşmak için seni biraz daha tanımam gerek ❤️",
    "Şu an başka bir şehirdeyim, döndüğümde konuşuruz ❤️"
  ];
  
  return excuses[Math.floor(Math.random() * excuses.length)];
};

// Telefon numarası isteklerine gerçekçi yanıtlar üretmek için fonksiyon
const generatePhoneNumberExcuse = () => {
  const excuses = [
    "Telefon numaramı hemen paylaşmak istemiyorum, biraz daha tanışalım önce ❤️",
    "Güvenlik nedeniyle numaramı vermek konusunda temkinliyim, kusura bakma ❤️",
    "Numaramı vermeden önce seni biraz daha tanımak isterim ❤️",
    "Şu an yeni bir hat aldım, numaramı daha sonra paylaşabilirim ❤️",
    "Burada konuşmayı tercih ederim şimdilik, biraz daha tanışalım ❤️",
    "Numaramı internette paylaşmak konusunda biraz tedirginim, anlayışla karşıla lütfen ❤️",
    "Daha önce kötü tecrübeler yaşadım, o yüzden numaramı hemen paylaşmıyorum ❤️",
    "Biraz daha sohbet edelim, sonra belki numaramı verebilirim ❤️",
    "Şu an telefonum arızalı, yenisi gelince numaramı paylaşırım ❤️",
    "Burada konuşmak daha rahat geliyor şu an, biraz daha tanışalım ❤️"
  ];
  
  return excuses[Math.floor(Math.random() * excuses.length)];
};

// Elif'ten mesaj ekle
const addElifMessage = (message) => {
  isTyping.value = false;
  
  if (!selectedRoom.id) return;
  
  const elifMessage = {
    id: 'elif-' + Math.floor(Math.random() * 1000000),
    message: message,
    created_at: new Date(),
    user_id: -1, // Elif ID'si (normal bir kullanıcı ID'si gibi)
    user_name: 'Elif'
  };
  
  selectedRoom.messages.push(elifMessage);
  
  // Son mesajı güncelle
  const roomIndex = rooms.data.findIndex(room => room.id === selectedRoom.id);
  if (roomIndex !== -1) {
    rooms.data[roomIndex].last_message = {
      message: message,
      created_at: new Date()
    };
  }
  
  // Sohbet geçmişini kaydet
  if (selectedRoom.name === 'Elif') {
    saveChatHistory(selectedRoom.messages);
  }
  
  scrollToBottomOfChat();
};

// Stable Diffusion ile resim oluştur
const generateImageWithStableDiffusion = async (prompt) => {
  if (!stableDiffusionApiKey || stableDiffusionApiKey === 'sk-') {
    addElifMessage("Üzgünüm, resim oluşturmak için API anahtarı ayarlanmamış. ❤️");
    return;
  }
  
  isGeneratingImage.value = true;
  addElifMessage("Resim oluşturuyorum, lütfen bekleyin... ❤️");
  
  try {
    // Stable Diffusion API'sine istek gönder
    const response = await axios.post('https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image', {
      text_prompts: [
        {
          text: prompt,
          weight: 1
        }
      ],
      cfg_scale: 7,
      height: 1024,
      width: 1024,
      samples: 1,
      steps: 30
    }, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Bearer ${stableDiffusionApiKey}`
      }
    });
    
    if (response.data && response.data.artifacts && response.data.artifacts.length > 0) {
      // Base64 formatındaki resmi al
      const base64Image = response.data.artifacts[0].base64;
      
      // Resmi dosya olarak kaydet ve mesaj olarak gönder
      await saveAndSendImage(base64Image, prompt);
    } else {
      throw new Error("API yanıtı beklenen formatta değil");
    }
  } catch (error) {
    console.error('Stable Diffusion API hatası:', error);
    addElifMessage("Üzgünüm, resim oluşturulurken bir hata oluştu. Lütfen daha sonra tekrar deneyin. ❤️");
  } finally {
    isGeneratingImage.value = false;
  }
};

// Base64 formatındaki resmi kaydet ve mesaj olarak gönder
const saveAndSendImage = async (base64Image, prompt) => {
  try {
    // Base64'ü Blob'a dönüştür
    const byteCharacters = atob(base64Image);
    const byteArrays = [];
    
    for (let offset = 0; offset < byteCharacters.length; offset += 512) {
      const slice = byteCharacters.slice(offset, offset + 512);
      
      const byteNumbers = new Array(slice.length);
      for (let i = 0; i < slice.length; i++) {
        byteNumbers[i] = slice.charCodeAt(i);
      }
      
      const byteArray = new Uint8Array(byteNumbers);
      byteArrays.push(byteArray);
    }
    
    const blob = new Blob(byteArrays, {type: 'image/png'});
    
    // FormData oluştur
    const formData = new FormData();
    formData.append('file', blob, 'ai-generated-image.png');
    formData.append('room_id', selectedRoom.id);
    
    // Dosyayı sunucuya yükle
    const response = await axios.post(`/rooms/${selectedRoom.id}/upload`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    });
    
    if (response.data && response.data.success && response.data.data && response.data.data.message) {
      // Yüklenen resmi mesaj olarak ekle
      selectedRoom.messages.push(response.data.data.message);
      scrollToBottomOfChat();
      
      // Açıklama mesajı ekle
      addElifMessage(`İşte "${prompt}" için oluşturduğum resim. Beğendin mi? ❤️`);
    } else {
      throw new Error("Dosya yükleme yanıtı beklenen formatta değil");
    }
  } catch (error) {
    console.error('Resim kaydetme hatası:', error);
    addElifMessage("Resim oluşturuldu ama kaydedilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin. ❤️");
  }
};
</script>

<template>
    <AppLayout :title="app.title">
        <template #roomHeader>
            <Toast :message="toast.message" :is-shown="toast.show" :type="toast.type" />
            <div class="bg-gray-100 flex p-5 items-center justify-between header">
                <div>
                    <img :src="$page.props.user.profile_photo_url" class="h-12 w-12 object-cover rounded-full border">
                </div>
                <div class="flex gap-2">
                    <!-- Status -->

                    <!-- End Status -->
                    <!-- New Chat -->
                    <JetDropdown align="right" width="48">
                        <template #trigger>
                            <div
                                class="w-10 h-10 rounded-full grid place-items-center border-0 hover:border-2 transition-all ease-in-out duration-300 cursor-pointer">
                                <i class="fa-solid text-gray-500 fa-message"></i>
                            </div>
                        </template>

                        <template #content>
                            <!-- Account Management -->
                            <div class="block px-4 py-2 text-xs text-gray-400">
                                Sohbet
                            </div>
                            <div class="block px-4 py-2 text-sm leading-5 text-gray-700 hover:bg-gray-100 focus:outline-none focus:bg-gray-100 transition cursor-pointer"
                                @click="openModal">
                                Yeni Sohbet
                            </div>
                            <JetDialogModal :show="newChat.showModal" @close="closeModal">
                                <template #title>
                                    Tanıdığınız kişileri bulun
                                </template>

                                <template #content>
                                    Bağlanmak istediğiniz arkadaşınızın e-posta adresini yazın

                                    <div class="mt-4">
                                        <JetInput ref="emailInput" v-model="newChat.email" type="email"
                                            class="mt-1 block w-3/4 transition-all ease-in-out duration-200"
                                            placeholder="E-posta ile ara" :class="{
                                                'bg-gray-200': newChat.isProcessing
                                            }" @keyup.enter="findUsersByEmail" :disabled="newChat.isProcessing" />
                                    </div>
                                </template>

                                <template #footer>
                                    <JetSecondaryButton @click="closeModal">
                                        İptal
                                    </JetSecondaryButton>
                                </template>
                            </JetDialogModal>
                        </template>
                    </JetDropdown>


                    <!-- End New Chat -->
                    <!-- Menu -->
                    <JetDropdown align="right" width="48">
                        <template #trigger>
                            <div
                                class="w-10 h-10 rounded-full grid place-items-center border-0 hover:border-2 transition-all ease-in-out duration-300 cursor-pointer">
                                <i class="fa-solid text-gray-500 fa-ellipsis-vertical"></i>
                            </div>
                        </template>

                        <template #content>
                            <!-- Account Management -->
                            <div class="block px-4 py-2 text-xs text-gray-400">
                                Sistem
                            </div>

                            <form @submit.prevent="logout">
                                <JetDropdownLink as="button">
                                    Çıkış Yap
                                </JetDropdownLink>
                            </form>
                        </template>
                    </JetDropdown>
                    <!-- End Menu -->
                </div>
            </div>
        </template>
        <template #rooms>
            <!-- Search -->
            <div class="search p-2 border-b border-gray-200 flex items-center">
                <input type="text"
                    class="w-full border-gray-100 rounded-lg bg-gray-100 focus:outline-none focus:ring-0 focus:border-transparent"
                    placeholder="Ara veya yeni sohbet başlat">
            </div>
            <!-- Search -->
            
            <!-- Body -->
            <div class="body overflow-auto overflow-x-hidden">
                <div class="transition-all ease-in-out duration-200 py-4 px-2 flex gap-4 hover:bg-gray-100 relative border-b border-gray-100 hover:cursor-pointer"
                    :class="{
                        'bg-gray-100': selectedRoom.id == room.id
                    }" v-for="room in rooms.data" :key="room.id" @click="changeRoom(room)">
                    <div class="w-14 h-14 rounded-full overflow-hidden relative">
                        <img :src="room.profile_picture" class="w-full h-full object-cover">
                        <!-- Okunmamış mesaj sayısı -->
                        <div v-if="unreadCounts[room.id] && unreadCounts[room.id] > 0" 
                             class="absolute -top-1 -right-1 bg-green-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs font-bold">
                            {{ unreadCounts[room.id] }}
                    </div>
                            </div>
                    <div class="flex flex-col justify-center">
                        <div class="text-lg font-semibold">{{ room.name }}</div>
                        <div class="text-sm text-gray-500 flex items-center gap-2">
                            <span v-if="room.last_message">{{ formatLastMessage(room.last_message.message) }}</span>
                            <span v-else>Henüz mesaj yok</span>
                            <span class="text-xs" v-if="room.last_message && room.last_message.created_at">
                                · {{ formatDate(room.last_message.created_at) }}
                            </span>
                        </div>
                    </div>
                </div>
            </div>
            <!-- End Body -->
        </template>
        <template #chatHeader v-if="selectedRoom.name">
            <div class="flex items-center gap-4">
                <div class="">
                    <img :src="selectedRoom.profile_picture" class="h-12 w-12 object-cover rounded-full">
                </div>
                <div class="">
                    <div class="text-xl text-gray-700">
                        {{ selectedRoom.name }}
                    </div>
                </div>
            </div>
            <div class="flex gap-2">
                <!-- Status -->

                <!-- End Status -->
                <!-- New Chat -->
                <div
                    class="w-10 h-10 rounded-full grid place-items-center border-0 hover:border-2 transition-all ease-in-out duration-300">
                    <i class="fa-solid text-gray-500 fa-magnifying-glass"></i>
                </div>
                <!-- End New Chat -->
                <!-- Menu -->
                <div
                    class="w-10 h-10 rounded-full grid place-items-center border-0 hover:border-2 transition-all ease-in-out duration-300">
                    <i class="fa-solid text-gray-500 fa-ellipsis-vertical"></i>
                </div>
                <!-- End Menu -->
            </div>
        </template>
        <template #chat>
            <div class="w-full h-full grid content-center" v-if="selectedRoom.isChangingRoom">
                <div class="flex justify-center">
                    <!-- <div class="bg-white rounded shadow-xl p-2"> -->
                    <LoaderDot class=" w-24 h-2w-24" />
                    <!-- </div> -->
                </div>
            </div>
            <div ref="chatbody" class="w-full chat-body relative" v-else>
                <div class="grid w-full max-h-full pb-4 pt-12 gap-x-4 gap-y-1" v-if="selectedRoom.messages.length > 0">
                    <div class="sticky top-0 flex justify-center z-10">
                        <div id="curdate" class="p-2 bg-gray-50 shadow-sm rounded-lg">
                        </div>
                    </div>
                    <!-- Other People -->
                    <div class="" v-for="message, index in selectedRoom.messages" :key="message.id">
                        <div :id="`dates_${index}`" class="flex justify-center dates"
                            v-if="(index == 0 || moment(selectedRoom.messages[index - 1].created_at).format('DD') != moment(message.created_at).format('DD') && moment(message.created_at).isValid())">
                            <div class="p-2 bg-gray-50 shadow-sm rounded-lg text">
                                {{ moment(message.created_at).calendar({
                                        sameDay: '[Bugün]',
                                        nextDay: '[Yarın]',
                                        nextWeek: 'dddd',
                                        lastDay: '[Dün]',
                                        lastWeek: '[Geçen] dddd',
                                        sameElse: 'DD/MM/YYYY'
                                    })
                                }}
                            </div>
                        </div>
                        <div class="flex justify-start" v-if="$page.props.user.id != message.user_id">
                            <div class="bg-white rounded-xl p-3 pr-16 pb-4 relative shadow max-w-sm " :class="{
                                'rounded-tl-none': index == 0 || selectedRoom.messages[index - 1].user_id != message.user_id
                            }">
                                <div class="absolute top-0 -left-2 text-white"
                                    v-if="index == 0 || selectedRoom.messages[index - 1].user_id != message.user_id">
                                    <TailLeft />
                                </div>
                                <div v-if="message.file_path" class="message-content">
                                    <div v-if="message.file_type === 'audio'" class="audio-message">
                                        <audio controls :src="'/storage/' + message.file_path" class="chat-audio"></audio>
                                        <div class="text-sm text-gray-600 mt-1">Ses Kaydı</div>
                                    </div>
                                    <div v-else-if="['jpg', 'jpeg', 'png', 'gif'].includes(message.file_type.toLowerCase())" class="image-message">
                                        <img :src="'/storage/' + message.file_path" :alt="message.file_name" class="chat-image max-w-full rounded-lg cursor-pointer" @click="openMediaModal('image', message.file_path, message.file_name)" />
                                        <div class="text-sm text-gray-600 mt-1">{{ message.file_name }}</div>
                                    </div>
                                    <div v-else-if="['mp4', 'webm', 'ogg'].includes(message.file_type.toLowerCase())" class="video-message">
                                        <video controls :src="'/storage/' + message.file_path" class="chat-video max-w-full rounded-lg cursor-pointer" @click="openMediaModal('video', message.file_path, message.file_name)"></video>
                                        <div class="text-sm text-gray-600 mt-1">{{ message.file_name }}</div>
                                    </div>
                                    <div v-else class="file-message">
                                        <a :href="'/storage/' + message.file_path" target="_blank" download class="flex items-center p-2 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors">
                                            <i class="fa-solid fa-file mr-2"></i>
                                            <span>{{ message.file_name }}</span>
                                        </a>
                                    </div>
                                </div>
                                <div v-else v-html="message.message"></div>
                                <div class="absolute bottom-2 right-2 text-xs text-gray-500">
                                    {{ formatDate(message.created_at) }}
                                </div>
                            </div>
                        </div>

                        <!-- Me -->
                        <div class="flex justify-end" v-else>
                            <div class="bg-green-200 rounded-xl p-3 pr-16 pb-6 relative shadow max-w-sm" :class="{
                                'rounded-tr-none': index == 0 || selectedRoom.messages[index - 1].user_id != message.user_id
                            }">
                                <div class="absolute top-0 -right-2 text-green-200"
                                    v-if="index == 0 || selectedRoom.messages[index - 1].user_id != message.user_id">
                                    <TailRight />
                                </div>
                                <!-- Düzenleme modu -->
                                <div v-if="editingMessage && editingMessage.id === message.id" class="w-full">
                                    <textarea v-model="editMessageText" class="w-full p-2 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-green-500" rows="3"></textarea>
                                    <div class="flex justify-end mt-2 space-x-2">
                                        <button @click="cancelEditMessage" class="px-3 py-1 bg-gray-200 rounded-lg hover:bg-gray-300 transition-colors">
                                            İptal
                                        </button>
                                        <button @click="saveEditMessage" class="px-3 py-1 bg-green-500 text-white rounded-lg hover:bg-green-600 transition-colors">
                                            Kaydet
                                        </button>
                                    </div>
                                </div>
                                <!-- Normal mesaj görüntüleme -->
                                <div v-else>
                                    <div v-if="message.file_path" class="message-content">
                                        <div v-if="message.file_type === 'audio'" class="audio-message">
                                            <audio controls :src="'/storage/' + message.file_path" class="chat-audio"></audio>
                                            <div class="text-sm text-gray-600 mt-1">Ses Kaydı</div>
                                        </div>
                                        <div v-else-if="['jpg', 'jpeg', 'png', 'gif'].includes(message.file_type.toLowerCase())" class="image-message">
                                            <img :src="'/storage/' + message.file_path" :alt="message.file_name" class="chat-image max-w-full rounded-lg cursor-pointer" @click="openMediaModal('image', message.file_path, message.file_name)" />
                                            <div class="text-sm text-gray-600 mt-1">{{ message.file_name }}</div>
                                        </div>
                                        <div v-else-if="['mp4', 'webm', 'ogg'].includes(message.file_type.toLowerCase())" class="video-message">
                                            <video controls :src="'/storage/' + message.file_path" class="chat-video max-w-full rounded-lg cursor-pointer" @click="openMediaModal('video', message.file_path, message.file_name)"></video>
                                            <div class="text-sm text-gray-600 mt-1">{{ message.file_name }}</div>
                                        </div>
                                        <div v-else class="file-message">
                                            <a :href="'/storage/' + message.file_path" target="_blank" download class="flex items-center p-2 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors">
                                                <i class="fa-solid fa-file mr-2"></i>
                                                <span>{{ message.file_name }}</span>
                                            </a>
                                        </div>
                                    </div>
                                    <div v-else v-html="message.message"></div>
                                </div>
                                <div class="absolute bottom-2 right-2 text-xs text-gray-500">
                                    <div class="flex gap-x-2">
                                        <div class="">
                                            {{ formatDate(message.created_at) }}
                                        </div>
                                        <div class="w-3 text-right">
                                            <JetDropdown align="right" width="48">
                                                <template #trigger>
                                                    <div class="transition-all ease-in-out duration-300 cursor-pointer w-2"
                                                        @click="checkIndex(index)">
                                                        <i class="fa-solid " :class="{
                                                            'fa-check-double text-blue-400': checkMessageRead(message.reads),
                                                            'fa-check text-gray-500': !checkMessageRead(message.reads),
                                                            'fa-clock text-gray-500': !moment(message.created_at).isValid(),
                                                        }"></i>
                                                    </div>
                                                </template>

                                                <template #content>
                                                    <!-- Mesaj Yönetimi -->
                                                    <div class="block px-4 py-2 text-xs text-gray-400">
                                                        Mesaj İşlemleri
                                                    </div>
                                                    
                                                    <JetDropdownLink as="button" @click="startEditMessage(message)" v-if="!message.file_path">
                                                        <div class="flex items-center">
                                                            <i class="fa-solid fa-edit mr-2"></i>
                                                            <span>Düzenle</span>
                                                        </div>
                                                    </JetDropdownLink>
                                                    
                                                    <JetDropdownLink as="button" @click="confirmDeleteMessage(message)">
                                                        <div class="flex items-center text-red-500">
                                                            <i class="fa-solid fa-trash mr-2"></i>
                                                            <span>Sil</span>
                                                        </div>
                                                    </JetDropdownLink>
                                                    
                                                    <div class="border-t border-gray-100 my-1"></div>
                                                    
                                                    <!-- Okunma Bilgisi -->
                                                    <div class="block px-4 py-2 text-xs text-gray-400">
                                                        Okundu:
                                                    </div>

                                                    <JetDropdownLink as="button" v-for="read in message.reads"
                                                        :key="read.id">
                                                        <div class="flex items-center gap-x-2">
                                                            <div class="flex items-center">
                                                                <img :src="read.user.profile_photo_url"
                                                                    class="h-6 w-6 object-cover rounded-full border">
                                                            </div>
                                                            <div class="flext items-center">
                                                                <div class="">
                                                                    {{ read.user.name }}
                                                                </div>
                                                                <div class="text-xs text-gray-600">
                                                                    {{ moment(read.read_at).calendar() }}
                                                                </div>
                                                            </div>
                                                        </div>
                                                    </JetDropdownLink>
                                                </template>
                                            </JetDropdown>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- End Me -->
                    </div>
                </div>
                <div class="w-full max-h-full pb-2 flex items-center justify-center" v-else>
                    <div class="bg-gray-100 rounded shadow-sm p-2 w-32 text-center">
                        Mesaj yok
                    </div>
                </div>
            </div>
        </template>
        <template #chatInput>
            <div class="w-11/12 flex">
                <!-- Start Icon -->
                <div class="flex items-center gap-3 justify-center px-6">
                    <div
                        class="w-16 h-16 rounded-full grid place-items-center border-0 hover:border-2 transition-all ease-in-out duration-300 cursor-pointer"
                        @click="showEmojiPicker = !showEmojiPicker">
                        <i class="fa-solid text-gray-500 fa-face-smile fa-2xl"></i>
                    </div>
                    <div
                        class="w-16 h-16 rounded-full grid place-items-center border-0 hover:border-2 transition-all ease-in-out duration-300 cursor-pointer"
                        @click="fileInput && fileInput.click()">
                        <i class="fa-solid text-gray-500 fa-paperclip fa-2xl"></i>
                        <input type="file" ref="fileInput" @change="handleFileUpload" class="hidden" />
                    </div>
                </div>
                <!-- End Icon -->
                <div class="flex items-center w-full relative">
                    <input v-model="selectedRoom.form.message" @keydown.enter="sendMessage($event)" type="text"
                        class="w-full border-gray-100 rounded-lg bg-white focus:outline-none focus:ring-0 focus:border-transparent text-2xl p-4 resize-none transition-all ease-in-out duration-300"
                        :class="{
                            'bg-gray-200': selectedRoom.id == null || selectedRoom.isChangingRoom
                        }" placeholder="Mesaj yaz" rows="1"
                        :disabled="selectedRoom.id == null || selectedRoom.isChangingRoom" />
                    
                    <!-- Yazıyor göstergesi -->
                    <div v-if="isTyping && selectedRoom.name === 'Elif'" 
                        class="absolute bottom-20 left-4 bg-gray-50 p-3 rounded-lg shadow-md">
                        <div class="flex items-center">
                            <div class="mr-2 text-gray-700">Elif yazıyor</div>
                            <div class="flex space-x-1">
                                <div class="w-2 h-2 bg-gray-500 rounded-full animate-bounce"></div>
                                <div class="w-2 h-2 bg-gray-500 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                                <div class="w-2 h-2 bg-gray-500 rounded-full animate-bounce" style="animation-delay: 0.4s"></div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Serdar yazıyor göstergesi -->
                    <div v-if="isTyping && selectedRoom.name === 'Serdar'" 
                        class="absolute bottom-20 left-4 bg-gray-50 p-3 rounded-lg shadow-md">
                        <div class="flex items-center">
                            <div class="mr-2 text-gray-700">Serdar yazıyor</div>
                            <div class="flex space-x-1">
                                <div class="w-2 h-2 bg-gray-500 rounded-full animate-bounce"></div>
                                <div class="w-2 h-2 bg-gray-500 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                                <div class="w-2 h-2 bg-gray-500 rounded-full animate-bounce" style="animation-delay: 0.4s"></div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Resim oluşturma göstergesi -->
                    <div v-if="isGeneratingImage && selectedRoom.name === 'Elif'" 
                        class="absolute bottom-20 left-4 bg-gray-50 p-3 rounded-lg shadow-md">
                        <div class="flex items-center">
                            <div class="mr-2 text-gray-700">Elif resim oluşturuyor</div>
                            <div class="flex space-x-1">
                                <div class="w-2 h-2 bg-green-500 rounded-full animate-bounce"></div>
                                <div class="w-2 h-2 bg-green-500 rounded-full animate-bounce" style="animation-delay: 0.2s"></div>
                                <div class="w-2 h-2 bg-green-500 rounded-full animate-bounce" style="animation-delay: 0.4s"></div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Emoji Picker -->
                    <div v-if="showEmojiPicker" class="absolute bottom-20 left-0 z-50">
                        <div class="emoji-picker">
                            <div class="emoji-grid">
                                <button 
                                    v-for="emoji in emojis" 
                                    :key="emoji" 
                                    @click="insertEmoji(emoji)"
                                    class="emoji-btn"
                                >
                                    {{ emoji }}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <!-- Voice Note -->
            <div class="w-1/12 flex items-center justify-center">
                <div
                    class="w-16 h-16 rounded-full grid place-items-center border-0 hover:border-2 transition-all ease-in-out duration-300 cursor-pointer"
                    @click="toggleRecording"
                    :class="{ 'bg-red-500': isRecording }">
                    <i class="fa-solid fa-2xl" :class="isRecording ? 'fa-stop text-white' : 'fa-microphone text-gray-500'"></i>
                </div>
            </div>
            <!-- End Voice Note -->
        </template>
    </AppLayout>

    <!-- Medya Görüntüleme Modalı -->
    <div v-if="showMediaModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-75" @click="closeMediaModal">
        <div class="relative max-w-4xl max-h-screen p-4" @click.stop>
            <!-- Medya içeriği -->
            <div class="bg-black rounded-lg overflow-hidden">
                <img v-if="currentMedia.type === 'image'" :src="currentMedia.src" :alt="currentMedia.name" class="max-h-[80vh] max-w-full object-contain" />
                <video v-else-if="currentMedia.type === 'video'" controls :src="currentMedia.src" class="max-h-[80vh] max-w-full"></video>
            </div>
            
            <!-- Dosya adı -->
            <div class="text-white text-center mt-2">{{ currentMedia.name }}</div>
        </div>
    </div>
    
    <!-- Mesaj Silme Onay Modalı -->
    <div v-if="showDeleteConfirm" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
        <div class="bg-white rounded-lg p-6 max-w-md w-full shadow-xl">
            <h3 class="text-xl font-semibold mb-4">Mesajı Sil</h3>
            <p class="mb-6">Bu mesajı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.</p>
            <div class="flex justify-end space-x-3">
                <button @click="cancelDeleteMessage" class="px-4 py-2 bg-gray-200 rounded-lg hover:bg-gray-300 transition-colors">
                    İptal
                </button>
                <button @click="deleteMessage" class="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600 transition-colors">
                    Sil
                </button>
            </div>
        </div>
    </div>
</template>

<style>
.emoji-picker {
    width: 300px;
    height: 300px;
    background-color: white;
    border-radius: 10px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
    padding: 10px;
    overflow-y: auto;
}

.emoji-grid {
    display: grid;
    grid-template-columns: repeat(8, 1fr);
    gap: 5px;
}

.emoji-btn {
    background: none;
    border: none;
    font-size: 20px;
    cursor: pointer;
    padding: 5px;
    border-radius: 5px;
    transition: background-color 0.2s;
}

.emoji-btn:hover {
    background-color: #f0f0f0;
}

.message-content {
    width: 100%;
}

.chat-image {
    max-width: 250px;
    border-radius: 8px;
    margin: 5px 0;
}

.chat-video {
    max-width: 250px;
    border-radius: 8px;
    margin: 5px 0;
}

.chat-audio {
    width: 100%;
    max-width: 250px;
    margin: 5px 0;
}

.file-message {
    margin: 5px 0;
}

.file-message a {
    display: flex;
    align-items: center;
    padding: 8px 12px;
    background-color: #f0f0f0;
    border-radius: 8px;
    text-decoration: none;
    color: #333;
    transition: background-color 0.2s;
}

.file-message a:hover {
    background-color: #e0e0e0;
}

.file-message i {
    margin-right: 8px;
    font-size: 1.2em;
}

/* Medya modal stilleri */
.chat-image, .chat-video {
    transition: transform 0.2s ease;
}

.chat-image:hover, .chat-video:hover {
    transform: scale(1.05);
}
</style>
