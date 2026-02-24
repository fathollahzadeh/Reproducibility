
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        U.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
VoteDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes
    FROM 
        Users U
    JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(H.Summary, 'No History') AS EditHistory,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentEdit
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT 
             PostId, STRING_AGG(Comment, '; ') AS Summary 
         FROM 
             PostHistory 
         WHERE 
             PostHistoryTypeId IN (4, 5, 6)
         GROUP BY 
             PostId) H ON P.Id = H.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.BadgeCount,
    US.UpVotes,
    US.DownVotes,
    US.QuestionCount,
    US.AnswerCount,
    US.TotalViews,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ViewCount,
    PS.EditHistory
FROM 
    UserStats US
JOIN 
    PostSummary PS ON US.UserId = PS.PostId
WHERE 
    US.Reputation > 1000
ORDER BY 
    US.Reputation DESC, PS.ViewCount DESC
LIMIT 50;
