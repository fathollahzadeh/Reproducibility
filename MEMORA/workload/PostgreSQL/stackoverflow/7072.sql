WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount
), PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        (SELECT COUNT(DISTINCT b.Id) FROM Badges b WHERE b.UserId = p.OwnerUserId) AS BadgeCount,
        (SELECT COUNT(DISTINCT ph.Id) FROM PostHistory ph WHERE ph.PostId = rp.PostId) AS EditCount
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
), FinalRanking AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (ORDER BY pd.Score DESC, pd.VoteCount DESC) AS FinalRank
    FROM 
        PostDetails pd
)
SELECT 
    Fr.FinalRank,
    Fr.PostId,
    Fr.Title,
    Fr.Score,
    Fr.ViewCount,
    Fr.CommentCount,
    Fr.VoteCount,
    Fr.BadgeCount,
    Fr.EditCount
FROM 
    FinalRanking Fr
WHERE 
    Fr.FinalRank <= 10
ORDER BY 
    Fr.FinalRank;