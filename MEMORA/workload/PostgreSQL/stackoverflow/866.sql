WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        COALESCE(v.upVotes, 0) - COALESCE(v.downVotes, 0) AS VoteScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(v.upVotes, 0) DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS upVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS downVotes
        FROM Votes 
        GROUP BY PostId
    ) v ON p.Id = v.PostId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.ViewCount,
        rp.VoteScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankPerUser <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        tp.Id,
        tp.Title,
        tp.ViewCount,
        tp.VoteScore,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.Id = pc.PostId
)
SELECT 
    fr.Id,
    fr.Title,
    fr.ViewCount,
    fr.VoteScore,
    fr.CommentCount,
    CASE 
        WHEN fr.VoteScore > 0 THEN 'Positive' 
        WHEN fr.VoteScore < 0 THEN 'Negative' 
        ELSE 'Neutral' 
    END AS ScoreStatus
FROM 
    FinalResults fr
ORDER BY 
    fr.VoteScore DESC, fr.ViewCount DESC
LIMIT 10;
