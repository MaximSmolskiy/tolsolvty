function [tolmax,argmax,envs,ccode] = tolsolvty(infA,supA,infb,supb,varargin) 
//
//  Вычисление максимума распознающего функционала допускового множества 
//  решений для интервальной системы линейных алгебраических уравнений 
// 
//  TOLSOLVTY(infA, supA, infb, supb) выдаёт значение максимума распознающего 
//  функционала для интервальной системы линейных уравнений Ax = b, у которой 
//  матрицы нижних и верхних концов элементов A  равны infA и supA, а векторы 
//  нижних и верхних концов правой части b  равны infb и supb соответственно. 
//  Кроме того, процедура выводит  заключение  о  разрешимости  интервальной 
//  линейной задачи  о допусках  с интервальной матрицей A = [infA, supA]  и 
//  вектором b = [infb, supb]  (т.е. о пустоте или непустоте допускового 
//  множества решений данной системы) и диагностику остановки алгоритма. 
//  
//  Синтаксис вызова:
//      [tolmax,argmax,envs,ccode] = tolsolvty(infA,supA,infb,supb, ... 
//                                                iprn,epsf,epsx,epsg,maxitn)
//  
//  Обязательные входные аргументы функции:
//       infA, supA - матрицы левых и правых концов интервальных коэффициентов 
//                    при неизвестных для интервальной системы линейных 
//                    алгебраических уравнений; они могут быть прямоугольными, 
//                    но должны иметь одинаковые размеры; 
//       infb, supb - векторы левых и правых концов интервалов правой части 
//                    интервальной системы линейных алгебраических уравнений. 
//  
//  Необязательные входные аргументы функции:
//             iprn - выдача протокола поиска; если iprn > 0 - информация 
//                    о ходе процесса печатается через каждые iprn-итераций; 
//                    если iprn <= 0 (значение по умолчанию), печати нет; 
//             epsf - допуск на точность по значению целевого функционала, 
//                    по умолчанию устанавливается 1.0e-6; 
//             epsx - допуск на точность по аргументу целевого функционала, 
//                    по умолчанию устанавливается 1.0e-6; 
//             epsg - допуск на малость нормы суперградиента функционала, 
//                    по умолчанию устанавливается 1.0e-6; 
//           maxitn - ограничение на количество шагов алгоритма, 
//                    по умолчанию устанавливается 2000. 
//  
//  Выходные аргументы функции: 
//           tolmax - значение максимума распознающего функционала;
//           argmax - доставляющий его вектор значений аргумента,который 
//                    лежит в допусковом множестве решений при tolmax>=0;
//             envs - значения образующих распознающего функционала в точке 
//                    его максимума, отсортированные по возрастанию; 
//            ccode - код завершения алгоритма (1 - по допуску epsf на 
//                    изменения значений функционала, 2 - по допуску epsg 
//                    на суперградиент, 3 - по допуску epsx на вариацию 
//                    аргумента, 4 - по числу итераций, 5 - не найден 
//                    максимум по направлению).
    
////////////////////////////////////////////////////////////////////////////////
// 
//  Эта  программа  выполняет  исследование  разрешимости  линейной  задачи 
//  о допусках для интервальной системы линейных уравнений Ax = b с матрицей 
//  A = [infA, supA] и правой частью b = [infb, supb] с помощью максимизации 
//  распознающего функционала Tol допускового множества решений этой системы. 
//  См. подробности в 
//      Шарый С.П. Конечномерный интервальный анализ. - Новосибирск: XYZ, 
//      2020. - Электронная книга, доступная на http://www.nsc.ru/interval/
//      параграф 6.4;
//      Shary S.P. Solving the linear interval tolerance problem //
//      Mathematics and Computers in Simulation. - 1995. - Vol. 39.
//      - P. 53-85.
// 
//  Для  максимизации  вогнутого  распознающего  функционала  используется 
//  вариант алгоритма суперградиентного подъёма с растяжением пространства 
//  в направлении  разности  последовательных суперградиентов, предложенный
//  (для случая минимизации) в работе 
//      Шор Н.З., Журбенко Н.Г. Метод минимизации, использующий операцию
//      растяжения пространства в направлении разности двух последовательных 
//      градинетов // Кибернетика. - 1971. - №3. - С. 51-59.  
//  В качестве основы этой части программы использована процедура негладкой 
//  оптимизации ralgb5, разработанная и реализованная П.И.Стецюком (Институт 
//  кибернетики НАН Украины, Киев). 
//  
//  С.П. Шарый, ФИЦ ИВТ, НГУ, 2007-2019. 
//  М.Л. Смольский, СПбГПУ, 2019-2021. 
//  
////////////////////////////////////////////////////////////////////////////////
  
// 
//   проверка корректности входных данных 
// 
  
mi = size(infA,1);  ni = size(infA,2); 
ms = size(supA,1);  ns = size(supA,2); 
if mi==ms then 
    m = ms 
else 
    error('Количество строк в матрицах левых и правых концов неодинаково') 
end 
if ni==ns then 
    n = ns  //  n - размерность пространства переменных 
else 
    error('Количество столбцов в матрицах левых и правых концов неодинаково') 
end 
  
ki = size(infb,1); 
ks = size(supb,1); 
if ki== ks then 
    k = ks 
else 
    error('Количество компонент у векторов левых и правых концов неодинаково') 
end 
if k ~= m then 
    error('Размеры матрицы системы не соответствуют размерам правой части') 
end 
  
////////////////////////////////////////////////////////////////////////////////
//  
//   задание параметров алгоритма суперградиентного подъёма 
//
maxitn = 2000;          //  ограничение на количество шагов алгоритма
nsims  = 30;            //  допустимое количество одинаковых шагов
epsf = 1.0e-6;          //  допуск на изменение значения функционала 
epsx = 1.0e-6;          //  допуск на изменение аргумента функционала
epsg = 1.0e-6;          //  допуск на норму суперградиента функционала
  
alpha = 2.3;            //  коэффициент растяжения пространства в алгоритме
hs = 1.0;               //  начальная величина шага одномерного поиска
nh = 3;                 //  число одинаковых шагов одномерного поиска 
q1 = 0.9;               //  q1, q2 - параметры адаптивной регулировки
q2 = 1.1;               //  шагового множителя
  
iprn = 0;               //  печать о ходе процесса через каждые iprn-итераций
                        //  (если iprn < 0, то печать подавляется)
  
////////////////////////////////////////////////////////////////////////////////
// 
//  переназначение параметров алгоритма, заданных пользователем 
// 
nargin = argn(2); 
if nargin >= 5 
    iprn = ceil(varargin(1)); 
    if nargin >= 6 
        epsf = varargin(2); 
        if nargin >= 7 
            epsx = varargin(3); 
            if nargin >= 8 
                epsg = varargin(4); 
                if nargin >= 9 
                    maxitn = varargin(5); 
                end 
            end 
        end 
    end 
end
  
////////////////////////////////////////////////////////////////////////////////
  
function [f,g,tt] = calcfg(x)
//
//  функция, вычисляющая значения f максимизируемого распознающего 
//  функционала допускового множества решений и его суперградиента g 
//  кроме того, выводится вектор tt значений образующих функционала 
//
    //  для быстрого вычисления образующих распознающего функционала 
    //  используются сокращённые формулы умножения интервальной матрицы 
    //  на точечный вектор, через середину и радиус 
    absx = abs(x); 
    Ac_x = Ac * x; 
    Ar_absx = Ar * absx; 
    infs = bc - (Ac_x + Ar_absx); 
    sups = bc - (Ac_x - Ar_absx); 
    tt = br - max(abs(infs), abs(sups)); 
  
    //  сборка значения всего распознающего функционала 
    [f, mc] = min(tt);
  
  
    //  вычисление суперградиента той образующей распознающего функционала, 
    //  на которой достигается предыдущий минимум 
    infA_mc = infA(mc, :)'; 
    supA_mc = supA(mc, :)'; 
    x_neg = x < 0; 
    x_nonneg = x >= 0; 
    dl = infA_mc .* x_neg + supA_mc .* x_nonneg; 
    ds = supA_mc .* x_neg + infA_mc .* x_nonneg; 
    if -infs(mc) <= sups(mc) 
        g = ds; 
    else 
        g = -dl; 
    end 
endfunction 
  
////////////////////////////////////////////////////////////////////////////////
// 
//  формируем начальное приближение x как решение либо псевдорешение 
//  'средней' точечной системы, если она не слишком плохо обусловлена,
//  иначе берём начальным приближением нулевой вектор 
// 
Ac = 0.5*(infA + supA); 
Ar = 0.5*(supA - infA); 
bc = 0.5*(infb + supb); 
br = 0.5*(supb - infb); 

sv = svd(Ac); 
minsv = min(sv); 
maxsv = max(sv); 
  
if ( minsv~=0 & maxsv/minsv < 1.e+12 ) 
    x = Ac\bc; 
else 
    x = zeros(n,1); 
end  
   
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
//
//  Рабочие массивы:
//      B - матрица обратного преобразования пространства аргументов
//      g - вектор суперградиента максимизируемого функционала 
//      g1,g2 - используются для хранения вспомогательных векторов
//      vf - вектор приращений функционала на последних nsims шагах алгоритма
  
B  = eye(n,n);                  //  инициализируем единичной матрицей 
vf = %inf*ones(nsims,1);        //  инициализируем массивом из бесконечностей 

////////////////////////////////////////////////////////////////////////////////
//
//  Присваивание строк оформления протокола работы программы 

TitLine = 'Протокол максимизации распознающего функционала Tol';
HorLine = '-----------------------------------------------------------';
TabLine = ' Шаг          Tol(x)          Tol(xx)  ВычФун/шаг  ВычФун';
  
////////////////////////////////////////////////////////////////////////////////
//  
//  установка начальных параметров, вывод заголовка протокола
//
w = 1.0/alpha - 1;
lp = iprn; 
  
[f,g0,tt] = calcfg(x); 
ff = f;   xx = x; 
cal = 1;  ncals = 1; 
  
if iprn > 0 
    printf('\n%100s',TitLine); 
    printf('\n%60s',HorLine); 
    printf('\n%77s',TabLine); 
    printf('\n%60s',HorLine); 
    printf('\n%5u%17g%17g%9u%9u',0,f,ff,cal,ncals); 
end 
  
////////////////////////////////////////////////////////////////////////////////
//  основной цикл программы: 
//      itn - счётчик числа итераций 
//      xx  - найденная точка максимума функционала 
//      ff  - значение функционала в точке максимума 
//      cal - количество вычислений функционала на текущем шаге 
//    ncals - общее количество вычислений целевого функционала 
// 
for itn = 1:maxitn; 
    pf = ff; 
    //  критерий останова по норме суперградиента 
    if  norm(g0) < epsg 
        ccode = 2; 
        break 
    end
    //  вычисляем суперградиент в преобразованном пространстве
    g1 = B' * g0;
    g = B * g1/norm(g1); 
    normg = norm(g);
    //  одномерный подъём по направлению dx:
    //      cal - счётчик шагов одномерного поиска,
    //      deltax - вариация аргумента в процессе поиска
    r = 1; 
    cal = 0; 
    deltax = 0;
    while ( r > 0. & cal <= 500 )
        cal = cal + 1; 
        x = x + hs*g; 
        deltax = deltax + hs*normg; 
        [f, g1, tt] = calcfg(x); 
        if f > ff 
            ff = f; 
            xx = x; 
        end 
        //  если прошло nh шагов одномерного подъёма, 
        //  то увеличиваем величину шага hs 
        if modulo(cal, nh) == 0 
            hs = hs*q2;
        end 
        r = g'*g1; 
    end
    //  если превышен лимит числа шагов одномерного подъёма, то выход
    if cal > 500 
        ccode = 5; 
        break; 
    end 
    //  если одномерный подъём занял один шаг, 
    //  уменьшаем величину шага hs 
    if cal == 1
        hs = hs*q1;
    end 
    //  уточняем статистику и при необходимости выводим её 
    ncals = ncals + cal;
    if itn == lp
        printf('\n%5u%17g%17g%9u%9u',itn,f,ff,cal,ncals);
        lp = lp + iprn;
    end
    //  если вариация аргумента в одномерном поиске мала, то выход
    if deltax < epsx 
        ccode = 3;  
        break; 
    end
    //   пересчитываем матрицу преобразования пространства 
    dg = B' * (g1 - g0);
    xi = dg / norm(dg);
    B = B + w*(B*xi)*xi';
    g0 = g1;
    //   проверка изменения значения функционала на последних nsims шагах,
    //   относительного либо абсолютного 
    vf(2:nsims) = vf(1:nsims-1);
    vf(1) = abs(ff - pf);
    if abs(ff) > 1 
        deltaf = sum(vf)/abs(ff);
    else
        deltaf = sum(vf);  
    end
    if deltaf < epsf 
        ccode = 1;  break
    end
    ccode = 4;
end
   
tolmax = ff;
argmax = xx;
  
//  сортируем образующие распознающего функционала по возрастанию 
tt = [(1:m)', tt];
[z,ind] = gsort(tt(:,2),'g','i');
envs = tt(ind,:);
   
////////////////////////////////////////////////////////////////////////////////
//  вывод результатов работы 
  
if iprn > 0
    if modulo(itn,iprn) ~= 0
        printf('\n%5u%17g%17g%9u%9u',itn,f,ff,cal,ncals); 
    end
    printf('\n%60s\n',HorLine);
end
   
////////////////////////////////////////////////////////////////////////////////
  
if tolmax >= 0
    printf('\n%48s\n\n','Интервальная линейная задача о допусках разрешима')
else 
    printf('\n%54s\n\n','Интервальная линейная задача о допусках не имеет решений')
end 
  
////////////////////////////////////////////////////////////////////////////////
  
if ( tolmax < 0. & abs(tolmax/epsf) < 10 ) 
    printf('%55s\n','Вычисленный максимум находится в пределах заданной точности')
    printf('%50s\n','- перезапустите программу с меньшими epsf и epsx, чтобы')
    printf('%55s\n\n','получить больше информации о разрешимости задачи о допусках')
end 
  
////////////////////////////////////////////////////////////////////////////////
  
endfunction
  
////////////////////////////////////////////////////////////////////////////////
  
