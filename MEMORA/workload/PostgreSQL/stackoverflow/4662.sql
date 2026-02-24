
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COALESCE(SUM(VB.BountyAmount), 0) AS TotalBounties,
        COUNT(CA.Id) AS AnswerCount,
        COUNT(C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes VB ON P.Id = VB.PostId AND VB.VoteTypeId = 8 
    LEFT JOIN Posts CA ON P.Id = CA.ParentId AND CA.PostTypeId = 2 
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PH.Comment
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
    AND PH.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
UserScore AS (
    SELECT 
        UserId,
        SUM(Score) AS TotalScore
    FROM (
        SELECT 
            P.OwnerUserId AS UserId,
            P.Score
        FROM Posts P
        WHERE P.PostTypeId = 1 
        UNION ALL
        SELECT 
            A.OwnerUserId AS UserId,
            A.Score
        FROM Posts A
        WHERE A.PostTypeId = 2 
    ) AS UserPosts
    GROUP BY UserId
)
SELECT 
    UR.UserId,
    UR.DisplayName,
    UR.Reputation,
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.TotalBounties,
    TP.AnswerCount,
    TP.CommentCount,
    RE.UserId AS LastEditedBy,
    RE.CreationDate AS LastEditDate,
    RE.Comment AS LastEditComment
FROM UserReputation UR
JOIN TopPosts TP ON UR.Rank <= 10
LEFT JOIN RecentEdits RE ON TP.PostId = RE.PostId
LEFT JOIN UserScore US ON UR.UserId = US.UserId
WHERE COALESCE(US.TotalScore, 0) > 1000
ORDER BY UR.Reputation DESC, TP.Score DESC;
