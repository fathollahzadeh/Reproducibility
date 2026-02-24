WITH UserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY (U.UpVotes - U.DownVotes) DESC) AS Rank
    FROM Users U
    WHERE U.Reputation > 100
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.LastActivityDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM Posts P
    LEFT JOIN UserScores US ON P.OwnerUserId = US.UserId
    WHERE P.PostTypeId = 1 AND P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AnswerCounts AS (
    SELECT 
        ParentId,
        COUNT(*) AS AnswerCount
    FROM Posts
    WHERE PostTypeId = 2
    GROUP BY ParentId
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    PD.Title,
    PD.CreationDate,
    PD.LastActivityDate,
    US.DisplayName,
    US.Reputation,
    US.NetVotes,
    COALESCE(AC.AnswerCount, 0) AS TotalAnswers,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    COALESCE(UB.BadgeNames, 'None') AS BadgeNames
FROM PostDetails PD
JOIN Users U ON PD.OwnerUserId = U.Id
JOIN UserScores US ON U.Id = US.UserId
LEFT JOIN AnswerCounts AC ON PD.PostId = AC.ParentId
LEFT JOIN UserBadges UB ON U.Id = UB.UserId
WHERE US.Rank <= 50
ORDER BY PD.LastActivityDate DESC
LIMIT 10;