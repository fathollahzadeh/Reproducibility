WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
TopBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Class = 1  
    GROUP BY 
        B.UserId
),
PostHistoryCounts AS (
    SELECT 
        PH.UserId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        PH.UserId
),
FinalStats AS (
    SELECT 
        US.UserId,
        US.DisplayName,
        US.Reputation,
        US.Views,
        US.UpVotes,
        US.DownVotes,
        US.PostCount,
        US.QuestionCount,
        US.AnswerCount,
        US.ClosedPostCount,
        COALESCE(TB.BadgeCount, 0) AS GoldBadgeCount,
        COALESCE(PHC.EditCount, 0) AS EditCount
    FROM 
        UserStats US
    LEFT JOIN 
        TopBadges TB ON US.UserId = TB.UserId
    LEFT JOIN 
        PostHistoryCounts PHC ON US.UserId = PHC.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    Views,
    UpVotes,
    DownVotes,
    PostCount,
    QuestionCount,
    AnswerCount,
    ClosedPostCount,
    GoldBadgeCount,
    EditCount
FROM 
    FinalStats
ORDER BY 
    Reputation DESC, PostCount DESC
LIMIT 10;