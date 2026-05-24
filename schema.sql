-- ============================================================
-- Digital Magazine Management System — Database Schema
-- Database: magazine_system (MySQL 8+)
-- ============================================================

-- ============================================================
-- TABLE: PUBLISHER
-- ============================================================
CREATE TABLE IF NOT EXISTS PUBLISHER (
    publisher_id INT PRIMARY KEY AUTO_INCREMENT,
    name         VARCHAR(100) NOT NULL,
    email        VARCHAR(150) NOT NULL UNIQUE,
    phone        VARCHAR(30),
    address      TEXT
);

-- ============================================================
-- TABLE: MAGAZINE
-- FK: publisher_id → PUBLISHER
-- ============================================================
CREATE TABLE IF NOT EXISTS MAGAZINE (
    mag_id       INT PRIMARY KEY AUTO_INCREMENT,
    title        VARCHAR(255) NOT NULL,
    language     VARCHAR(50),
    category     VARCHAR(100),
    p_date       DATE,
    price        FLOAT DEFAULT 0,
    publisher_id INT,
    FOREIGN KEY (publisher_id) REFERENCES PUBLISHER(publisher_id) ON DELETE SET NULL
);

-- ============================================================
-- TABLE: AUTHOR
-- ============================================================
CREATE TABLE IF NOT EXISTS AUTHOR (
    author_id      INT PRIMARY KEY AUTO_INCREMENT,
    name           VARCHAR(100) NOT NULL,
    email          VARCHAR(150) NOT NULL UNIQUE,
    phone          VARCHAR(30),
    specialization VARCHAR(100)
);

-- ============================================================
-- TABLE: EDITOR
-- ============================================================
CREATE TABLE IF NOT EXISTS EDITOR (
    editor_id  INT PRIMARY KEY AUTO_INCREMENT,
    name       VARCHAR(100) NOT NULL,
    email      VARCHAR(150) NOT NULL UNIQUE,
    experience INT DEFAULT 0
);

-- ============================================================
-- TABLE: ARTICLE
-- FK: mag_id → MAGAZINE (cascade delete)
-- ============================================================
CREATE TABLE IF NOT EXISTS ARTICLE (
    article_id INT PRIMARY KEY AUTO_INCREMENT,
    title      VARCHAR(255) NOT NULL,
    content    TEXT,
    pages      INT,
    p_date     DATE,
    mag_id     INT,
    FOREIGN KEY (mag_id) REFERENCES MAGAZINE(mag_id) ON DELETE CASCADE
);

-- ============================================================
-- JUNCTION TABLE: WRITES  (M:N  Author ↔ Article)
-- ============================================================
CREATE TABLE IF NOT EXISTS WRITES (
    author_id  INT NOT NULL,
    article_id INT NOT NULL,
    PRIMARY KEY (author_id, article_id),
    FOREIGN KEY (author_id)  REFERENCES AUTHOR(author_id)   ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES ARTICLE(article_id) ON DELETE CASCADE
);

-- ============================================================
-- JUNCTION TABLE: EDITS  (1:N  Editor → Article)
-- ============================================================
CREATE TABLE IF NOT EXISTS EDITS (
    editor_id  INT NOT NULL,
    article_id INT NOT NULL,
    PRIMARY KEY (editor_id, article_id),
    FOREIGN KEY (editor_id)  REFERENCES EDITOR(editor_id)   ON DELETE CASCADE,
    FOREIGN KEY (article_id) REFERENCES ARTICLE(article_id) ON DELETE CASCADE
);

-- ============================================================
-- TABLE: SUBSCRIBER
-- ============================================================
CREATE TABLE IF NOT EXISTS SUBSCRIBER (
    subscriber_id     INT PRIMARY KEY AUTO_INCREMENT,
    name              VARCHAR(100) NOT NULL,
    email             VARCHAR(150) NOT NULL UNIQUE,
    phone             VARCHAR(30),
    city              VARCHAR(100),
    subscription_type VARCHAR(20) DEFAULT 'Monthly'
);

-- ============================================================
-- TABLE: SUBSCRIPTION  (M:N  Subscriber ↔ Magazine)
-- ============================================================
CREATE TABLE IF NOT EXISTS SUBSCRIPTION (
    subscription_id INT PRIMARY KEY AUTO_INCREMENT,
    subscriber_id   INT NOT NULL,
    mag_id          INT NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    CONSTRAINT chk_dates CHECK (end_date > start_date),
    FOREIGN KEY (subscriber_id) REFERENCES SUBSCRIBER(subscriber_id) ON DELETE CASCADE,
    FOREIGN KEY (mag_id)        REFERENCES MAGAZINE(mag_id)          ON DELETE CASCADE
);

-- ============================================================
-- TABLE: Article_Log  (for trigger logging)
-- ============================================================
CREATE TABLE IF NOT EXISTS Article_Log (
    log_id       INT PRIMARY KEY AUTO_INCREMENT,
    article_name VARCHAR(255),
    action_time  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- TRIGGER: after_article_insert
-- ============================================================
DROP TRIGGER IF EXISTS after_article_insert;
CREATE TRIGGER after_article_insert
AFTER INSERT ON ARTICLE
FOR EACH ROW
BEGIN
    INSERT INTO Article_Log (article_name, action_time)
    VALUES (NEW.title, NOW());
END;

-- ============================================================
-- VIEW: Article_Details
-- ============================================================
CREATE OR REPLACE VIEW Article_Details AS
SELECT
    a.article_id,
    a.title       AS article_title,
    a.content     AS article_content,
    a.pages,
    a.p_date      AS article_date,
    m.title       AS magazine_title,
    m.mag_id      AS magazine_id,
    m.category    AS magazine_category,
    GROUP_CONCAT(DISTINCT au.name ORDER BY au.name SEPARATOR ', ') AS author_names,
    GROUP_CONCAT(DISTINCT ed.name ORDER BY ed.name SEPARATOR ', ') AS editor_names
FROM ARTICLE a
LEFT JOIN MAGAZINE m  ON a.mag_id = m.mag_id
LEFT JOIN WRITES  w   ON a.article_id = w.article_id
LEFT JOIN AUTHOR  au  ON w.author_id  = au.author_id
LEFT JOIN EDITS   e   ON a.article_id = e.article_id
LEFT JOIN EDITOR  ed  ON e.editor_id  = ed.editor_id
GROUP BY a.article_id, a.title, a.content, a.pages, a.p_date, m.title, m.mag_id, m.category;

-- ============================================================
-- INDEXES (no IF NOT EXISTS — not supported in MySQL)
-- ============================================================
CREATE INDEX idx_magazine_title    ON MAGAZINE(title);
CREATE INDEX idx_magazine_category ON MAGAZINE(category);
CREATE INDEX idx_author_name       ON AUTHOR(name);

-- ============================================================
-- SEED DATA  (INSERT IGNORE skips duplicates on re-run)
-- ============================================================

INSERT IGNORE INTO PUBLISHER (name, email, phone, address) VALUES
('Condé Nast',           'editorial@condenast.com',      '+1-212-286-2860', '1 World Trade Center, New York, NY 10007'),
('Hearst Communications','contact@hearst.com',           '+1-212-649-2000', '300 West 57th Street, New York, NY 10019'),
('Meredith Corporation', 'press@meredith.com',           '+1-515-284-3000', '225 Liberty Street, New York, NY 10281'),
('National Geographic Partners', 'info@natgeo.com',      '+1-202-857-7000', '1145 17th Street NW, Washington, DC 20036'),
('Forbes Media',         'editors@forbes.com',           '+1-212-620-2200', '499 Washington Blvd, Jersey City, NJ 07310'),
('Springer Nature',      'customerservice@springernature.com', '+49-6221-345-0', 'Tiergartenstrasse 17, 69121 Heidelberg, Germany'),
('Nikkei Business Publications', 'global@nikkei.com',    '+81-3-6811-1111', '1-3-7 Otemachi, Chiyoda-ku, Tokyo 100-8066');

INSERT IGNORE INTO MAGAZINE (title, language, category, p_date, price, publisher_id) VALUES
('Wired',                    'English',  'Technology',   '2025-03-01',  6.99, 1),
('Vogue',                    'English',  'Fashion',      '2025-04-01', 8.99, 1),
('Esquire',                  'English',  'Lifestyle',    '2025-02-15',  7.99, 2),
('Cosmopolitan',             'English',  'Lifestyle',    '2025-05-01',  5.99, 2),
('Better Homes & Gardens',   'English',  'Home & Garden','2025-01-20',  4.99, 3),
('National Geographic',      'English',  'Science',      '2025-06-01',  9.99, 4),
('Forbes',                   'English',  'Business',     '2025-04-15', 12.99, 5),
('Nature',                   'English',  'Science',      '2025-03-20', 14.95, 6),
('Scientific American',      'English',  'Science',      '2025-05-10',  7.99, 6),
('Nikkei Asia',              'English',  'Business',     '2025-06-15', 10.50, 7),
('Le Monde Diplomatique',    'French',   'Politics',     '2025-04-01',  5.50, 6),
('The New Yorker',           'English',  'Culture',      '2025-05-20',  9.99, 1);

INSERT IGNORE INTO AUTHOR (name, email, phone, specialization) VALUES
('Ananth Krishnan',     'ananth.krishnan@thehindu.co.in',  '+91-98410-55621', 'Geopolitics'),
('Kara Swisher',        'kara@vox.com',                    '+1-415-555-0178', 'Technology'),
('Siddhartha Mukherjee','s.mukherjee@columbia.edu',        '+1-212-555-0342', 'Medicine'),
('Margaret Atwood',     'margaret@anansi.ca',              '+1-416-555-0291', 'Literature'),
('Fareed Zakaria',      'fareed.zakaria@cnn.com',          '+1-212-555-0463', 'International Affairs'),
('Priya Ramani',        'priya.ramani@livemint.com',       '+91-98200-71834', 'Culture & Society'),
('Ed Yong',             'ed.yong@theatlantic.com',         '+44-20-7946-0958','Science'),
('Nikkei Staff Report', 'reports@nikkei.com',              '+81-3-6811-1200', 'Asian Markets');

INSERT IGNORE INTO EDITOR (name, email, experience) VALUES
('Graydon Carter',      'graydon.carter@condenast.com',    25),
('Anna Wintour',        'anna.wintour@vogue.com',          38),
('David Remnick',       'david.remnick@newyorker.com',     30),
('Radhika Jones',       'radhika.jones@vanityfair.com',    18),
('Susan Goldberg',      'susan.goldberg@natgeo.com',       22),
('Magdalena Skipper',   'magdalena.skipper@nature.com',    15);

INSERT IGNORE INTO ARTICLE (title, content, pages, p_date, mag_id) VALUES
('Inside OpenAI: The Race to Build Safe AGI',
 'In a sprawling office complex in San Francisco, over 1,500 researchers are working around the clock to solve what many consider the most consequential engineering challenge in human history: building artificial general intelligence that is safe, aligned, and beneficial.

Since the release of GPT-4 in early 2023, OpenAI has accelerated its research into alignment techniques, interpretability, and red-teaming. CEO Sam Altman has repeatedly stated that the companys mission is not simply to build AGI first, but to build it safely. Yet critics argue that the pace of development has outstripped the pace of safety research.

The companys latest model, internally codenamed Orion, reportedly demonstrates emergent reasoning capabilities that surprised even its creators. Researchers describe it as the first system to consistently pass doctoral-level exams across multiple disciplines without task-specific fine-tuning.

But the race is far from over. Competitors like Anthropic, Google DeepMind, and Metas FAIR lab are investing billions into their own frontier models. The geopolitical dimension has also intensified, with both the US and China framing AGI development as a matter of national security.

As the stakes rise, so do the questions. Who should govern AGI? How do we ensure it serves all of humanity? And what happens if we get it wrong? These are the questions that keep OpenAIs safety team up at night — and they dont have all the answers yet.',
 14, '2025-03-01', 1),

('How Quantum Chips Will Reshape Cybersecurity',
 'The cybersecurity landscape is on the verge of a seismic shift. Quantum computing, long dismissed as a distant theoretical concern, has taken a giant leap forward with Googles announcement of its 1,000-qubit Willow processor.

At its core, the threat is mathematical. Most modern encryption — including RSA and elliptic-curve cryptography — relies on the computational difficulty of factoring large numbers or solving discrete logarithm problems. Classical computers would take thousands of years to break these codes. A sufficiently powerful quantum computer could do it in hours.

Governments and corporations are scrambling to adopt post-quantum cryptography (PQC) standards. In 2024, NIST finalized its first set of PQC algorithms, including CRYSTALS-Kyber for key encapsulation and CRYSTALS-Dilithium for digital signatures. But the transition is massive: every secure communication protocol, every certificate authority, every VPN tunnel needs to be upgraded.

The concept of "harvest now, decrypt later" has added urgency. Intelligence agencies around the world are believed to be storing encrypted communications today, waiting for quantum computers powerful enough to decrypt them tomorrow.

Experts estimate that enterprises have a window of 5 to 10 years to complete the migration. Those who delay risk exposing decades of sensitive data.',
 9, '2025-03-01', 1),

('The Met Gala 2025: Fashion as Political Theatre',
 'Under the soaring arches of the Metropolitan Museum of Art, the first Monday in May once again transformed into fashions most electrifying night. The 2025 Met Gala, themed "Threads of Resistance," invited designers and celebrities to explore how clothing has been used as a tool of political protest throughout history.

Zendaya arrived in a gown inspired by the suffragette movement, its white silk embedded with hand-stitched excerpts from the 19th Amendment. Timothee Chalamet wore a deconstructed military uniform by Raf Simons, a commentary on the aesthetics of war.

But it was Priyanka Chopra who stole the headlines with a sari reimagined by Sabyasachi Mukherjee, featuring embroidery depicting scenes from Indias independence movement. The piece took 12 artisans over 3,000 hours to complete.

Critics praised the evenings departure from pure spectacle toward meaningful commentary. "Fashion has always been political," said Andrew Bolton, the Costume Institutes head curator. "This year, we simply stopped pretending otherwise."

The exhibition, which opens to the public on May 10, features over 150 garments spanning five centuries of sartorial dissent.',
 10, '2025-04-01', 2),

('Spring 2025 Runway Report: Milan and Paris',
 'The Spring 2025 collections in Milan and Paris signaled a dramatic return to craftsmanship, with designers moving away from the logomania and streetwear influences that dominated recent seasons.

In Milan, Miuccia Prada presented a collection rooted in intellectual minimalism — structured silhouettes in muted earth tones, with hand-finished seams visible as a design element rather than a flaw. At Bottega Veneta, Matthieu Blazy continued his exploration of stealth luxury, unveiling leather pieces so supple they moved like jersey.

Paris, meanwhile, was all about drama. At Dior, Maria Grazia Chiuri staged her show in the Tuileries Garden, presenting floor-length gowns inspired by Impressionist paintings. Each piece was hand-dyed to mimic the watercolor palettes of Monet and Renoir.

Sustainability was no longer a talking point but a baseline expectation. Stella McCartney debuted a fully biodegradable evening gown, while Balenciaga announced that 80 percent of its Spring collection used recycled or upcycled materials.

The consensus among critics: fashion is growing up, trading hype for substance.',
 8, '2025-04-01', 2),

('The Modern Gentleman Guide to Remote Work',
 'Five years after the pandemic permanently reshaped the workplace, remote work has evolved from a temporary arrangement into a sophisticated lifestyle choice — and it demands its own code of conduct.

The modern remote worker is not lounging in pajamas on a couch. He has invested in a dedicated workspace with proper ergonomics: a height-adjustable desk, a monitor at eye level, and a chair that costs more than his first car. He understands that the background of his video calls is a form of self-presentation.

Communication is the cornerstone. The best remote workers over-communicate by default. They write clear, concise messages. They understand the difference between a Slack message, an email, and a meeting — and they choose the right medium every time.

But perhaps the most underrated skill is knowing when to stop. Without the physical boundary of leaving an office, work can bleed into every waking hour. Setting boundaries — a hard stop at 6 PM, no email on weekends, a genuine lunch break — is not laziness. It is discipline.

The gentleman works from anywhere. But he never lets anywhere become everywhere.',
 7, '2025-02-15', 3),

('Why Gen Z Is Rewriting the Rules of Dating',
 'For a generation raised on dating apps, the rules of romantic engagement have been completely rewritten. But not in the way you might expect.

According to a 2025 Pew Research study, Gen Z is dating less frequently than any previous generation at the same age. Nearly 35 percent of adults aged 18 to 25 report having never been in a romantic relationship. The reasons are complex: financial pressures, mental health awareness, and a fundamental skepticism about traditional relationship structures.

The apps themselves have evolved. Hinge has introduced AI-powered "compatibility coaches" that analyze conversation patterns and suggest date ideas. Bumble now offers a "slow dating" mode that limits matches to two per day, encouraging deeper engagement over rapid swiping.

But many young people are abandoning apps altogether in favor of IRL (in real life) connections. Running clubs, book clubs, and pottery classes have become the new singles bars. The hashtag #TouchGrass has over 2 billion views on TikTok.

"Gen Z doesnt want less connection," says relationship therapist Dr. Anika Patel. "They want more intentional connection. They are rejecting the commodification of romance."',
 6, '2025-05-01', 4),

('Drought-Resistant Gardens for a Warming Planet',
 'As climate change intensifies droughts across the American West, Southwest, and Mediterranean regions, homeowners are rethinking the traditional lawn. The result is a quiet revolution in residential landscaping.

Xeriscaping — designing gardens that require minimal irrigation — has moved from a niche practice to a mainstream movement. In 2024, Las Vegas banned ornamental grass in new developments. Phoenix now offers rebates of up to $3 per square foot for homeowners who replace turf with drought-resistant alternatives.

The plant palette has expanded dramatically. Native species like California poppies, desert marigolds, and blue grama grass are being combined with Mediterranean imports like lavender, rosemary, and olive trees. The result is gardens that are not only water-wise but strikingly beautiful.

Soil health is equally critical. Mulching with 3 to 4 inches of organic material reduces evaporation by up to 70 percent. Drip irrigation systems, controlled by smart sensors that monitor soil moisture in real time, have cut water usage in pilot programs by half.

The movement extends beyond individual homes. Cities like Tucson and Albuquerque are redesigning public parks around native plantings, proving that sustainability and beauty are not mutually exclusive.',
 12, '2025-01-20', 5),

('Lost City Discovered Under the Amazon Canopy',
 'Deep in the Ecuadorian Amazon, beneath a canopy so dense that sunlight barely reaches the forest floor, archaeologists have uncovered the remains of a city that challenges everything we thought we knew about pre-Columbian South America.

Using LiDAR technology — laser scanning from aircraft that can penetrate dense vegetation — a team led by Dr. Stephane Rostain of the French National Centre for Scientific Research revealed a network of earthen mounds, roads, and plazas covering an area of approximately 300 square kilometers.

The city, which flourished between roughly 500 BCE and 600 CE, was home to an estimated 100,000 people. Its residents built sophisticated drainage systems, terraced agricultural fields, and ceremonial platforms connected by wide causeways.

"This discovery forces us to completely rethink the history of the Amazon," says Dr. Rostain. "The idea that the rainforest was an untouched wilderness before European contact is simply wrong. These were complex, urbanized societies."

The findings, published in the journal Science, suggest that the Amazon basin may have supported populations comparable to those of ancient Mesopotamia or the Indus Valley. Excavations are expected to continue for the next decade.',
 16, '2025-06-01', 6),

('Mapping the Deep Ocean: What We Still Dont Know',
 'We have better maps of the Moon and Mars than we do of our own ocean floor. As of 2025, only 26 percent of the global seabed has been mapped to modern standards — a number that the Nippon Foundation-GEBCO Seabed 2030 project aims to change.

The challenges are immense. The ocean averages 3,688 meters in depth, and some trenches plunge below 10,000 meters. At these depths, the pressure is over 1,000 times atmospheric. Sonar signals sent from ships take up to 20 seconds to bounce back from the deepest points.

New technologies are accelerating the effort. Autonomous underwater vehicles (AUVs) like the Kongsberg HUGIN series can operate at depths of 6,000 meters, scanning the seabed with centimeter-level resolution. Satellite-derived gravity measurements can infer broad seafloor topography, guiding where to deploy more precise instruments.

The discoveries have been remarkable. In 2024 alone, researchers mapped a previously unknown underwater mountain range in the South Atlantic and discovered hydrothermal vent fields teeming with life forms unknown to science.

Beyond scientific curiosity, accurate ocean maps are critical for understanding climate change, planning submarine cable routes, managing fisheries, and assessing tsunami risks. The deep ocean is not empty — it is unexplored.',
 11, '2025-06-01', 6),

('Billionaires 2025: The Global Wealth Shift to Asia',
 'For the first time in the history of the Forbes Billionaires List, Asia is home to more billionaires than North America and Europe combined. The shift, which has been building for a decade, accelerated dramatically in 2024 driven by booming tech sectors in India, semiconductor wealth in Taiwan and South Korea, and the maturation of Southeast Asian digital economies.

India alone added 94 new billionaires in the past year, bringing its total to 271. Mukesh Ambani remains the continents richest individual, with a net worth of $138 billion, buoyed by Reliance Jios expansion into financial services and AI infrastructure.

China, despite its real estate downturn and regulatory crackdowns, still boasts 473 billionaires. The survivors have pivoted from property to electric vehicles, batteries, and advanced manufacturing. BYDs Wang Chuanfu saw his wealth double as the company overtook Tesla in global EV sales.

Meanwhile, Americas billionaire class is undergoing generational transition. As Buffett, Soros, and Murdoch enter their 90s, a new cohort of AI and biotech founders is rising. Jensen Huang of Nvidia, whose net worth crossed $120 billion, is now the worlds fifth-richest person.

The global wealth map is being redrawn. The question is whether political institutions can keep pace.',
 18, '2025-04-15', 7),

('How CRISPR Is Curing Sickle Cell Disease',
 'In December 2023, the FDA approved Casgevy, the worlds first CRISPR-based gene therapy, for the treatment of sickle cell disease. Eighteen months later, the results are nothing short of transformative.

Sickle cell disease affects approximately 100,000 Americans and millions worldwide, predominantly in communities of African descent. The condition causes red blood cells to deform into rigid, crescent shapes that block blood vessels, triggering excruciating pain crises, organ damage, and shortened lifespans.

Casgevy, developed by Vertex Pharmaceuticals and CRISPR Therapeutics, works by editing a patients own stem cells to reactivate fetal hemoglobin — a form of the oxygen-carrying protein that naturally suppresses sickling. The process involves extracting bone marrow, editing the cells in a laboratory using CRISPR-Cas9, and reinfusing them after chemotherapy.

Of the 97 patients treated in clinical trials, 93 have been free of vaso-occlusive crises for over 12 months. Many describe the experience as being reborn.

But significant challenges remain. The treatment costs approximately $2.2 million per patient, and the chemotherapy conditioning regimen carries serious risks, including infertility. Researchers are now working on in-vivo approaches that would deliver CRISPR directly into the body, potentially reducing costs by an order of magnitude.',
 13, '2025-03-20', 8),

('Gravitational Waves Reveal a New Class of Black Holes',
 'The Laser Interferometer Gravitational-Wave Observatory (LIGO), now in its fourth observing run with upgraded sensitivity, has detected gravitational waves from a merger involving a black hole of approximately 850 solar masses — far larger than any previously observed through gravitational wave astronomy.

The discovery fills a critical gap in astrophysics known as the "mass gap." Stellar-mass black holes, formed from collapsing stars, typically range from 5 to 100 solar masses. Supermassive black holes at galactic centers weigh millions to billions of solar masses. The intermediate range — hundreds to thousands of solar masses — has been a theoretical prediction with scant observational evidence.

"This is the smoking gun for intermediate-mass black holes," said Dr. Salvatore Vitale of MIT, a member of the LIGO Scientific Collaboration. "It tells us that these objects exist, they merge, and we can detect them."

The signal, designated GW250112, was detected simultaneously by LIGO facilities in Hanford, Washington, and Livingston, Louisiana, as well as the Virgo detector in Italy. The merger occurred approximately 5 billion light-years from Earth.

Theoretical models suggest these intermediate black holes form through repeated mergers in dense stellar environments like globular clusters. The detection opens a new window into understanding how supermassive black holes grow over cosmic time.',
 10, '2025-03-20', 8),

('The Neuroscience of Creativity',
 'What happens in the brain when a poet finds the perfect metaphor, or a physicist sees a new connection between seemingly unrelated equations? Neuroscience is finally beginning to answer this ancient question.

Using functional MRI and advanced EEG techniques, researchers at the University of Cambridge have identified what they call the "creative network" — a dynamic interplay between three brain systems. The default mode network generates spontaneous ideas. The executive control network evaluates and refines them. And the salience network acts as a switch, deciding when to let the mind wander and when to focus.

Creativity, it turns out, is not about one flash of genius. It is about the brains ability to toggle rapidly between divergent thinking (generating many possibilities) and convergent thinking (selecting the best one). The most creative individuals are those whose brains can make this switch most fluidly.

Environmental factors matter enormously. Moderate ambient noise (around 70 decibels, roughly the level of a coffee shop) enhances creative performance compared to silence. Blue and green environments boost divergent thinking. Even a brief walk increases creative output by an average of 60 percent.

Perhaps most surprisingly, mild boredom appears to be a powerful creative catalyst. When the brain is under-stimulated, it begins generating internal narratives and connections — the very process that underlies creative insight.',
 9, '2025-05-10', 9),

('Japans Semiconductor Comeback Strategy',
 'Japan once dominated the global semiconductor industry, commanding over 50 percent of the market in the late 1980s. By 2020, that share had fallen to just 10 percent. Now, backed by over 4 trillion yen ($27 billion) in government subsidies, Japan is mounting an ambitious comeback.

At the center of this effort is Rapidus, a consortium-backed company that aims to manufacture cutting-edge 2-nanometer chips by 2027. The company has secured a technology partnership with IBM and is building a state-of-the-art fabrication facility in Chitose, Hokkaido.

The strategy goes beyond catching up with TSMC and Samsung. Japan is positioning itself as an indispensable link in the global supply chain by leveraging its existing strengths: specialty materials, manufacturing equipment, and advanced packaging.

Companies like Tokyo Electron, Shin-Etsu Chemical, and JSR already control dominant market shares in photoresists, silicon wafers, and etching equipment — materials without which no advanced chip can be manufactured anywhere in the world.

The geopolitical context is equally important. With US-China tensions making supply chains vulnerable, Japan offers a politically stable, technologically advanced alternative. The question is whether Rapidus can achieve in five years what TSMC built over three decades.',
 12, '2025-06-15', 10),

('Macron and the Crisis of European Liberalism',
 'When Emmanuel Macron swept to power in 2017, he was hailed as the savior of European liberalism — a young, dynamic centrist who would hold the line against rising populism. Eight years later, that narrative has collapsed.

Macrons approval ratings hover around 23 percent, the lowest of any Fifth Republic president at this point in their tenure. The pension reform protests of 2023 evolved into a broader anti-establishment movement. His party, Renaissance, lost its parliamentary majority in the 2024 legislative elections, forcing an uneasy cohabitation with a fragmented opposition.

But Macrons troubles are symptomatic of a deeper crisis. Across Europe, centrist liberal parties are being squeezed between a resurgent far right and a radicalized left. In Germany, the FDP collapsed below the 5 percent threshold. In the Netherlands, Geert Wilders formed a government. In Italy, Giorgia Meloni consolidated power.

The liberal vision of open markets, European integration, and multicultural tolerance has not disappeared, but it has lost its emotional appeal. Voters battered by inflation, housing crises, and cultural anxiety are looking for more visceral answers.

"Liberalism forgot that politics is not just about policy," says political scientist Yascha Mounk. "It is about identity, belonging, and dignity. Until liberals learn to speak that language, they will continue to lose."',
 8, '2025-04-01', 11),

('The Untold Story of a War Correspondent in Sudan',
 'On April 15, 2023, war erupted in Khartoum. The Sudanese Armed Forces and the Rapid Support Forces turned the capital into a battlefield, and within weeks, the conflict had displaced millions. Most international journalists fled. Amira Hassan stayed.

Hassan, a Sudanese-British freelance journalist, spent 14 months reporting from inside the conflict zone — dodging airstrikes, negotiating checkpoints manned by child soldiers, and documenting atrocities that the world was largely ignoring.

"The hardest part was not the danger," she says from a hotel room in Nairobi, where she is recovering from shrapnel injuries. "It was the silence. I would file stories about mass graves, about systematic sexual violence, about famine — and they would get a fraction of the coverage of a celebrity divorce."

Her reporting, published across multiple outlets including The Guardian, Al Jazeera, and this magazine, provided some of the only independent documentation of events in Darfur, where the RSF has been accused of ethnic cleansing.

Hassan received the 2025 Pulitzer Prize for International Reporting. In her acceptance speech, she said: "This prize belongs to the people of Sudan, who are living through a catastrophe that the world has chosen to forget. Do not look away."',
 14, '2025-05-20', 12);

INSERT IGNORE INTO WRITES (author_id, article_id) VALUES
(2,1),(2,2),(6,3),(6,4),(4,5),(6,6),(7,7),(1,8),(7,9),(5,10),(3,11),(7,12),(7,13),(8,14),(5,15),(4,16),(1,9),(3,13);

INSERT IGNORE INTO EDITS (editor_id, article_id) VALUES
(1,1),(1,2),(2,3),(2,4),(1,5),(4,6),(4,7),(5,8),(5,9),(1,10),(6,11),(6,12),(6,13),(3,14),(3,15),(3,16);

INSERT IGNORE INTO SUBSCRIBER (name, email, phone, city, subscription_type) VALUES
('Arjun Mehta',        'arjun.mehta@gmail.com',        '+91-98765-43210', 'Mumbai',        'Yearly'),
('Sneha Iyer',         'sneha.iyer@outlook.com',       '+91-87654-32109', 'Bengaluru',     'Monthly'),
('James O\'Sullivan',  'james.osullivan@protonmail.com','+1-617-555-0142', 'Boston',        'Lifetime'),
('Amelia Richardson',  'a.richardson@yahoo.co.uk',      '+44-20-7946-0231','London',        'Yearly'),
('Takeshi Yamamoto',   'takeshi.yamamoto@docomo.ne.jp', '+81-90-1234-5678','Tokyo',         'Yearly'),
('Sophie Dubois',      'sophie.dubois@orange.fr',       '+33-6-12-34-56-78','Paris',        'Monthly'),
('Ravi Shankar Gupta', 'ravi.gupta@rediffmail.com',     '+91-99887-76655', 'Delhi',         'Yearly'),
('Elena Petrova',      'elena.petrova@yandex.ru',       '+7-916-123-4567', 'Moscow',        'Monthly'),
('Chen Wei',           'chen.wei@qq.com',               '+86-138-0013-8000','Shanghai',     'Lifetime'),
('Fatima Al-Rashidi',  'fatima.rashidi@gmail.com',       '+971-50-123-4567','Dubai',         'Yearly');

INSERT IGNORE INTO SUBSCRIPTION (subscriber_id, mag_id, start_date, end_date) VALUES
(1, 1,  '2025-01-01', '2026-01-01'),
(1, 7,  '2025-04-01', '2026-04-01'),
(2, 6,  '2025-03-01', '2025-09-01'),
(3, 1,  '2024-06-01', '2027-06-01'),
(3, 12, '2024-06-01', '2027-06-01'),
(3, 8,  '2025-01-01', '2028-01-01'),
(4, 2,  '2025-02-01', '2026-02-01'),
(4, 12, '2025-05-01', '2026-05-01'),
(5, 10, '2025-06-01', '2026-06-01'),
(5, 8,  '2025-03-01', '2026-03-01'),
(6, 11, '2025-04-01', '2025-10-01'),
(6, 2,  '2025-01-15', '2025-07-15'),
(7, 7,  '2025-04-15', '2026-04-15'),
(7, 9,  '2025-05-01', '2026-05-01'),
(8, 6,  '2025-02-01', '2025-08-01'),
(9, 10, '2025-06-15', '2028-06-15'),
(9, 1,  '2025-03-01', '2028-03-01'),
(10, 7, '2025-05-01', '2026-05-01'),
(10, 6, '2025-06-01', '2026-06-01');
