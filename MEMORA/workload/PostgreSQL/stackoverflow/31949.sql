WITH RECURSIVE UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        (SELECT COUNT(*) FROM Badges B WHERE B.UserId = U.Id) AS TotalBadges,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS QuestionRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
        AND P.Score > 0
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate,
        CASE
            WHEN U.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Active'
            ELSE 'Inactive'
        END AS UserStatus
    FROM 
        Users U
),
VoteCounts AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)
SELECT 
    Q.Title,
    Q.CreationDate,
    U.DisplayName AS OwnerDisplayName,
    U.Reputation,
    B.TotalBadges,
    QC.UpVotes,
    QC.DownVotes,
    CASE 
        WHEN QC.UpVotes IS NOT NULL THEN QC.UpVotes
        ELSE 0
    END AS UpVoteCount,
    CASE 
        WHEN QC.DownVotes IS NOT NULL THEN QC.DownVotes
        ELSE 0
    END AS DownVoteCount,
    UA.UserStatus
FROM 
    TopQuestions Q
JOIN 
    Users U ON Q.OwnerUserId = U.Id
LEFT JOIN 
    UserBadges B ON U.Id = B.UserId
LEFT JOIN 
    VoteCounts QC ON Q.PostId = QC.PostId
JOIN 
    ActiveUsers UA ON U.Id = UA.Id
WHERE 
    Q.QuestionRank <= 10 
ORDER BY 
    Q.Score DESC, Q.ViewCount DESC;