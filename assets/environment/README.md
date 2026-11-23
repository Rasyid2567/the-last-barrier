# Aset Lingkungan Labirin Rongga Hidung / Saluran Pernafasan (Nasal Cavity Labyrinth)
*The Last Barrier: Inside Us*

Semua aset lingkungan dan labirin ditata modular berdasarkan anatomi rongga hidung (*Nasal Cavity & Turbinates*):

---

## 1. Dinding Labirin (`assets/environment/walls/`)
Sesuai struktur anatomi rongga hidung pada gambar referensi:
### A. Tembok Tepi: Tulang Tengkorak / Tulang Hidung (*Bone Walls*)
Permukaan atasnya rata seperti tanah gading/krem berpori (struktur trabekular/tulang spons):
- **`wall_bone_top.png`**: Permukaan atas tulang spons (*trabecular bone matrix* warna gading/krem/beige berpori).
- **`wall_bone_front.png`**: Tampak depan vertikal tulang dengan lapisan periosteum.
- **`wall_bone_block.png`**: Blok utuh dinding tulang tepi (32×64).
- **`wall_bone_block.tscn`**: Prefab dinding tulang berkolisi.

### B. Tembok Tengah: Konka Nasalis / Mukosa Merah (*Turbinate Walls*)
Dinding pembentuk labirin di bagian tengah berwarna merah daging mukosa lembap seperti lipatan konka pada gambar referensi (*Superior, Middle, & Inferior Turbinates*):
- **`wall_turbinate_top.png`**: Permukaan atas konka nasalis (merah daging mukosa berlekuk lembut dengan kilauan lembap).
- **`wall_turbinate_front.png`**: Tampak depan vertikal lipatan konka dengan rumbai silia halus di dasarnya.
- **`wall_turbinate_block.png`**: Blok utuh dinding konka merah (32×64).
- **`wall_turbinate_block.tscn`**: Prefab dinding konka merah berkolisi.

---

## 2. Lantai & Alur Panduan (`assets/environment/ground/`)
- **`floor_mucosa.png`**: Lantai epitel mukosa lembap di dasar rongga hidung (*meatus nasalis*).
- **`floor_cilia.png`**: Jalur silia berumbai pengarah aliran udara pernafasan.
- **`floor_mucus.png`**: Ubin genangan sekresi lendir/mukus pekat di area jalan buntu.
- **`map_respiratory_ground.png`**: Komposisi lantai utuh (3840×2176 dengan skala 2x):
  - Tepi luar berpagar dinding tulang berpori.
  - Lorong-lorong labirin diapit oleh dinding konka merah.
  - Aliran garis bio-luminesen cyan memandu rute dari pintu masuk ke persimpangan, arena boss, dan pintu keluar.

---

## 3. Pintu, Kunci & Objek Labirin (`assets/environment/objects/`)
- **`exit_gate.tscn` / `exit_gate.gd`**: Pintu katup organ menuju stage selanjutnya (terbuka jika Cyro membawa Kunci Antigen).
- **`key_antigen.tscn` / `key_antigen.gd`**: Kunci Enzim Antigen bercahaya kuning-emas yang dijatuhkan oleh Mini-Boss Virus.
- **`prop_mucus_trap.tscn` & `prop_dust_crystal.tscn`**: Perangkap lendir dan kotoran debu di lorong-lorong jalan buntu.
- **`prop_alveolus.tscn` & `prop_oxygen_node.tscn`**: Kantung udara dan penerang rute jalan.

---

## 4. Mini-Boss (`assets/enemies/virus/`)
- **`virus_miniboss.tscn` / `virus_miniboss.gd`**: Mini-Boss Virus berpatroli di sarang arena timur laut. Diserang oleh Cyro dengan tombol Spasi / J / Klik Kiri (4 kali serangan) untuk menjatuhkan Kunci Antigen.
