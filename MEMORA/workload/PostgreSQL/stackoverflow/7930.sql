
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId  -- Added to avoid grouping issues later
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 500 AND
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore
    FROM 
        RankedPosts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
CommentsWithVotes AS (
    SELECT 
        c.PostId,
        COUNT(V.Id) AS VoteCount,
        AVG(c.Score) AS AvgCommentScore
    FROM 
        Comments c
    LEFT JOIN 
        Votes V ON c.PostId = V.PostId
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.AnswerCount,
        t.PostCount,
        t.TotalScore,
        cv.VoteCount,
        cv.AvgCommentScore
    FROM 
        RankedPosts r
    JOIN 
        TopUsers t ON r.OwnerUserId = t.OwnerUserId
    JOIN 
        CommentsWithVotes cv ON r.PostId = cv.PostId
    WHERE 
        r.PostRank = 1
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.AnswerCount,
    f.PostCount,
    f.TotalScore,
    f.VoteCount,
    f.AvgCommentScore
FROM 
    FinalResults f
ORDER BY 
    f.TotalScore DESC, f.ViewCount DESC
FETCH FIRST 10 ROWS ONLY;  -- Changed LIMIT to standard SQL FETCH FIRST
