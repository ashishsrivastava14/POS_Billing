$outDir = "d:\Projects\InHouseWebsites\MobileApp\POS_Billing\assets\products"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Product ID -> search keywords for loremflickr.com
$products = @(
    # Groceries & Staples (c1)
    @{ id="p1";  q="salt,packet" },
    @{ id="p2";  q="sunflower,oil" },
    @{ id="p3";  q="basmati,rice" },
    @{ id="p4";  q="wheat,flour,atta" },
    @{ id="p5";  q="toor,dal,lentil" },
    @{ id="p6";  q="turmeric,powder" },
    @{ id="p7";  q="chilli,powder,red" },
    @{ id="p8";  q="sugar,granulated" },
    @{ id="p9";  q="moong,dal,lentil" },
    @{ id="p10"; q="saffola,oil,cooking" },
    @{ id="p11"; q="rajma,kidney,beans" },
    @{ id="p12"; q="chana,dal,lentil" },
    @{ id="p13"; q="poha,flattened,rice" },
    @{ id="p14"; q="semolina,rava,sooji" },
    @{ id="p15"; q="gram,flour,besan" },
    @{ id="p16"; q="instant,noodles,maggi" },
    @{ id="p17"; q="tomato,ketchup" },
    @{ id="p18"; q="black,pepper,spice" },
    @{ id="p19"; q="ghee,clarified,butter" },
    @{ id="p20"; q="mustard,seeds" },
    @{ id="p21"; q="cumin,seeds,spice" },
    @{ id="p22"; q="urad,dal,lentil" },
    @{ id="p23"; q="refined,flour,maida" },
    @{ id="p24"; q="coriander,powder,spice" },
    @{ id="p25"; q="garam,masala,spice" },

    # Dairy & Eggs (c2)
    @{ id="p26"; q="milk,carton,fresh" },
    @{ id="p27"; q="butter,packet,dairy" },
    @{ id="p28"; q="cheese,slices" },
    @{ id="p29"; q="yogurt,curd,dahi" },
    @{ id="p30"; q="paneer,cottage,cheese" },
    @{ id="p31"; q="eggs,carton,dozen" },
    @{ id="p32"; q="cream,dairy,fresh" },
    @{ id="p33"; q="milk,slim,skimmed" },
    @{ id="p34"; q="lassi,yogurt,drink" },
    @{ id="p35"; q="buttermilk,drink" },
    @{ id="p36"; q="dahi,yogurt,pot" },
    @{ id="p37"; q="cheese,spread" },
    @{ id="p38"; q="flavored,yogurt,fruit" },
    @{ id="p39"; q="whipping,cream" },
    @{ id="p40"; q="cottage,cheese,fresh" },
    @{ id="p41"; q="milkshake,butterscotch" },
    @{ id="p42"; q="fresh,cream,carton" },
    @{ id="p43"; q="brown,eggs" },
    @{ id="p44"; q="soy,milk,plant" },
    @{ id="p45"; q="condensed,milk,tin" },

    # Beverages (c3)
    @{ id="p46"; q="coca,cola,bottle" },
    @{ id="p47"; q="pepsi,cola,bottle" },
    @{ id="p48"; q="tea,packet,leaves" },
    @{ id="p49"; q="coffee,instant,jar" },
    @{ id="p50"; q="sprite,lemon,soda" },
    @{ id="p51"; q="mountain,dew,green" },
    @{ id="p52"; q="red,bull,energy" },
    @{ id="p53"; q="water,bottle,mineral" },
    @{ id="p54"; q="mango,juice,carton" },
    @{ id="p55"; q="orange,juice,tropicana" },
    @{ id="p56"; q="green,tea,bags" },
    @{ id="p57"; q="horlicks,malt,drink" },
    @{ id="p58"; q="chocolate,malt,drink" },
    @{ id="p59"; q="apple,fizz,drink" },
    @{ id="p60"; q="lime,soda,drink" },
    @{ id="p61"; q="fanta,orange,drink" },
    @{ id="p62"; q="coconut,water,fresh" },
    @{ id="p63"; q="glucose,powder,energy" },
    @{ id="p64"; q="orange,tang,powder" },
    @{ id="p65"; q="rose,syrup,drink" },

    # Snacks & Biscuits (c4)
    @{ id="p66"; q="potato,chips,lays" },
    @{ id="p67"; q="butter,cookies,biscuit" },
    @{ id="p68"; q="biscuits,parle,glucose" },
    @{ id="p69"; q="puffed,snack,kurkure" },
    @{ id="p70"; q="bhujia,namkeen,snack" },
    @{ id="p71"; q="oreo,biscuit,chocolate" },
    @{ id="p72"; q="nachos,triangle,snack" },
    @{ id="p73"; q="chocolate,biscuit,premium" },
    @{ id="p74"; q="salty,biscuit,crackers" },
    @{ id="p75"; q="pringles,chips,tube" },
    @{ id="p76"; q="dairy,milk,chocolate" },
    @{ id="p77"; q="kitkat,chocolate,wafer" },
    @{ id="p78"; q="chocolate,bar,caramel" },
    @{ id="p79"; q="bourbon,biscuit,chocolate" },
    @{ id="p80"; q="marie,biscuit,plain" },
    @{ id="p81"; q="digestive,biscuit,wheat" },
    @{ id="p82"; q="aloo,bhujia,snack" },
    @{ id="p83"; q="doritos,nachos,corn" },
    @{ id="p84"; q="candy,gems,chocolate" },
    @{ id="p85"; q="chocolate,chip,cookies" },
    @{ id="p86"; q="chocolate,bar,munch" },
    @{ id="p87"; q="sev,namkeen,savory" },

    # Household & Cleaning (c5)
    @{ id="p88"; q="detergent,powder,laundry" },
    @{ id="p89"; q="dishwash,bar,soap" },
    @{ id="p90"; q="toilet,cleaner,bottle" },
    @{ id="p91"; q="floor,cleaner,mopping" },
    @{ id="p92"; q="glass,cleaner,spray" },
    @{ id="p93"; q="scrub,pad,sponge" },
    @{ id="p94"; q="laundry,detergent,tide" },
    @{ id="p95"; q="fabric,softener,laundry" },
    @{ id="p96"; q="mosquito,spray,repellent" },
    @{ id="p97"; q="mosquito,repellent,liquid" },
    @{ id="p98"; q="trash,bags,garbage" },
    @{ id="p99"; q="air,freshener,room" },
    @{ id="p100"; q="dishwash,liquid,soap" },
    @{ id="p101"; q="aluminium,foil,roll" },
    @{ id="p102"; q="cling,wrap,plastic" },
    @{ id="p103"; q="paper,towel,kitchen" },
    @{ id="p104"; q="toilet,paper,roll" },
    @{ id="p105"; q="naphthalene,moth,balls" },
    @{ id="p106"; q="mop,refill,cleaning" },
    @{ id="p107"; q="room,spray,freshener" },

    # Personal Care (c6)
    @{ id="p108"; q="toothpaste,tube,dental" },
    @{ id="p109"; q="soap,bar,dove" },
    @{ id="p110"; q="shampoo,bottle,hair" },
    @{ id="p111"; q="body,lotion,moisturizer" },
    @{ id="p112"; q="razor,blade,shaving" },
    @{ id="p113"; q="handwash,liquid,soap" },
    @{ id="p114"; q="sunscreen,lotion,spf" },
    @{ id="p115"; q="vaseline,petroleum,jelly" },
    @{ id="p116"; q="toothbrush,dental,oral" },
    @{ id="p117"; q="face,wash,cleanser" },
    @{ id="p118"; q="soap,bar,lifebuoy" },
    @{ id="p119"; q="coconut,oil,hair" },
    @{ id="p120"; q="mouthwash,oral,rinse" },
    @{ id="p121"; q="sanitary,pads,hygiene" },
    @{ id="p122"; q="hair,gel,styling" },
    @{ id="p123"; q="deodorant,spray,body" },
    @{ id="p124"; q="cotton,buds,swabs" },
    @{ id="p125"; q="bandaid,plaster,first" },
    @{ id="p126"; q="shaving,cream,foam" },
    @{ id="p127"; q="face,cream,skin" },

    # Fruits & Vegetables (c7)
    @{ id="p128"; q="banana,bunch,yellow" },
    @{ id="p129"; q="apple,red,fruit" },
    @{ id="p130"; q="tomato,red,vegetable" },
    @{ id="p131"; q="onion,brown,vegetable" },
    @{ id="p132"; q="potato,vegetable,brown" },
    @{ id="p133"; q="green,chilli,pepper" },
    @{ id="p134"; q="ginger,root,fresh" },
    @{ id="p135"; q="garlic,bulb,fresh" },
    @{ id="p136"; q="carrot,orange,vegetable" },
    @{ id="p137"; q="capsicum,bell,pepper" },
    @{ id="p138"; q="cucumber,green,vegetable" },
    @{ id="p139"; q="spinach,green,leaves" },
    @{ id="p140"; q="cauliflower,white,vegetable" },
    @{ id="p141"; q="lemon,yellow,citrus" },
    @{ id="p142"; q="coriander,cilantro,herb" },
    @{ id="p143"; q="orange,citrus,fruit" },
    @{ id="p144"; q="grapes,green,fruit" },
    @{ id="p145"; q="pomegranate,red,fruit" },
    @{ id="p146"; q="eggplant,brinjal,purple" },
    @{ id="p147"; q="okra,ladyfinger,green" },

    # Frozen & Ready-to-Eat (c8)
    @{ id="p148"; q="frozen,peas,green" },
    @{ id="p149"; q="frozen,mixed,vegetables" },
    @{ id="p150"; q="frozen,corn,sweet" },
    @{ id="p151"; q="chicken,nuggets,frozen" },
    @{ id="p152"; q="frozen,paratha,bread" },
    @{ id="p153"; q="french,fries,frozen" },
    @{ id="p154"; q="samosa,frozen,snack" },
    @{ id="p155"; q="cup,noodles,instant" },
    @{ id="p156"; q="dal,makhani,ready" },
    @{ id="p157"; q="popcorn,kernels,corn" },
    @{ id="p158"; q="spring,rolls,frozen" },
    @{ id="p159"; q="oats,instant,breakfast" },
    @{ id="p160"; q="pasta,spaghetti,italian" },
    @{ id="p161"; q="pizza,base,dough" },
    @{ id="p162"; q="soya,chunks,protein" },
    @{ id="p163"; q="upma,mix,breakfast" },
    @{ id="p164"; q="soup,mix,instant" },
    @{ id="p165"; q="vermicelli,noodles,thin" },

    # Baby & Kids (c9)
    @{ id="p166"; q="baby,cereal,food" },
    @{ id="p167"; q="baby,powder,talc" },
    @{ id="p168"; q="diapers,baby,pampers" },
    @{ id="p169"; q="baby,soap,mild" },
    @{ id="p170"; q="baby,shampoo,gentle" },
    @{ id="p171"; q="baby,wipes,wet" },
    @{ id="p172"; q="baby,lotion,skin" },
    @{ id="p173"; q="baby,formula,milk" },
    @{ id="p174"; q="baby,oil,massage" },
    @{ id="p175"; q="kids,toothpaste,bubble" },
    @{ id="p176"; q="ragi,cereal,baby" },
    @{ id="p177"; q="diaper,rash,cream" },
    @{ id="p178"; q="cereal,bar,kids" },
    @{ id="p179"; q="sippy,cup,baby" },
    @{ id="p180"; q="baby,feeding,bottle" },

    # Bakery & Bread (c10)
    @{ id="p181"; q="white,bread,loaf" },
    @{ id="p182"; q="brown,bread,whole" },
    @{ id="p183"; q="pav,bun,bread" },
    @{ id="p184"; q="rusk,biscuit,toast" },
    @{ id="p185"; q="cake,mix,baking" },
    @{ id="p186"; q="croissant,pastry,bakery" },
    @{ id="p187"; q="fruit,cake,bakery" },
    @{ id="p188"; q="muffin,cupcake,bakery" },
    @{ id="p189"; q="multigrain,bread,whole" },
    @{ id="p190"; q="burger,bun,sesame" },
    @{ id="p191"; q="hotdog,bun,bread" },
    @{ id="p192"; q="garlic,bread,baked" },
    @{ id="p193"; q="baking,powder,can" },
    @{ id="p194"; q="vanilla,essence,extract" },
    @{ id="p195"; q="cocoa,powder,chocolate" },
    @{ id="p196"; q="yeast,baking,dry" },
    @{ id="p197"; q="sandwich,bread,sliced" },
    @{ id="p198"; q="puff,pastry,flaky" },
    @{ id="p199"; q="honey,jar,golden" },
    @{ id="p200"; q="jam,fruit,jar" }
)

$total = $products.Count
$done = 0

foreach ($p in $products) {
    $done++
    $file = Join-Path $outDir "$($p.id).jpg"
    if (Test-Path $file) {
        Write-Host "[$done/$total] SKIP $($p.id) (exists)"
        continue
    }
    $url = "https://loremflickr.com/200/200/$($p.q)"
    try {
        $result = curl.exe -L -o $file $url --max-time 20 -s -w "%{http_code}" 2>&1
        if (Test-Path $file) {
            $size = (Get-Item $file).Length
            if ($size -lt 1000) {
                Remove-Item $file -Force
                Write-Host "[$done/$total] FAIL $($p.id) (too small: $size bytes)"
            } else {
                Write-Host "[$done/$total] OK   $($p.id) ($size bytes)"
            }
        } else {
            Write-Host "[$done/$total] FAIL $($p.id) (no file created)"
        }
    } catch {
        Write-Host "[$done/$total] FAIL $($p.id) - $_"
    }
    # Small delay to avoid rate limiting
    Start-Sleep -Milliseconds 200
}

Write-Host "`nDone! Downloaded images to $outDir"
$count = (Get-ChildItem $outDir -Filter "*.jpg" | Measure-Object).Count
Write-Host "Total images: $count / $total"
