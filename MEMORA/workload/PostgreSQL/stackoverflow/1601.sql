WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM
        Users U
),
TopPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.OwnerUserId,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC, P.CreationDate DESC) AS UserPostRank
    FROM
        Posts P
    WHERE
        P.Score > 0
),
PostComments AS (
    SELECT
        C.PostId,
        COUNT(*) AS CommentCount,
        MAX(C.CreationDate) AS LastCommentDate
    FROM
        Comments C
    GROUP BY
        C.PostId
),
JoinedData AS (
    SELECT
        UP.DisplayName,
        UP.Reputation,
        TP.Title,
        TP.Score,
        TP.ViewCount,
        PC.CommentCount,
        PC.LastCommentDate
    FROM
        UserReputation UP
    LEFT JOIN
        TopPosts TP ON UP.UserId = TP.OwnerUserId
    LEFT JOIN
        PostComments PC ON TP.PostId = PC.PostId
    WHERE
        TP.UserPostRank = 1
),
FinalResults AS (
    SELECT
        JD.DisplayName,
        JD.Reputation,
        JD.Title,
        JD.Score,
        JD.ViewCount,
        COALESCE(JD.CommentCount, 0) AS CommentCount,
        JD.LastCommentDate,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId IN (SELECT PostId FROM TopPosts WHERE UserPostRank = 1)) AS TotalVotes
    FROM
        JoinedData JD
)

SELECT
    FR.DisplayName,
    FR.Reputation,
    FR.Title,
    FR.Score,
    FR.ViewCount,
    FR.CommentCount,
    FR.LastCommentDate,
    FR.TotalVotes,
    CASE 
        WHEN FR.Reputation > 1000 THEN 'High Reputation'
        WHEN FR.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM
    FinalResults FR
ORDER BY
    FR.Reputation DESC,
    FR.Score DESC;
