WITH PostVoteSummary AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN V.VoteTypeId IN (6, 10, 12) THEN 1 END) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
UserBadgeSummary AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
QuestionDetail AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        Q.AnswerCount,
        COALESCE(VS.UpVotes - VS.DownVotes, 0) AS Score,
        UB.BadgeCount,
        UB.BadgeNames
    FROM 
        Posts P
    JOIN 
        PostVoteSummary VS ON P.Id = VS.PostId
    LEFT JOIN 
        UserBadgeSummary UB ON P.OwnerUserId = UB.UserId
    LEFT JOIN 
        (SELECT 
            ParentId, COUNT(*) AS AnswerCount 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId) Q ON P.Id = Q.ParentId
    WHERE 
        P.PostTypeId = 1
)
SELECT 
    QD.QuestionId,
    QD.Title,
    QD.CreationDate,
    U.DisplayName,
    COALESCE(QD.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(QD.BadgeNames, 'No Badges') AS UserBadges,
    QD.Score,
    CASE 
        WHEN QD.Score <= 0 OR QD.BadgeCount IS NULL THEN 'Inactive'
        WHEN QD.Score > 0 AND QD.BadgeCount > 0 THEN 'Active with Badges'
        ELSE 'Active without Badges'
    END AS UserStatus
FROM 
    QuestionDetail QD
JOIN 
    Users U ON QD.OwnerUserId = U.Id
WHERE 
    QD.Score > (SELECT AVG(Score) FROM QuestionDetail)
ORDER BY 
    QD.Score DESC, QD.CreationDate ASC
LIMIT 15
OFFSET 5;