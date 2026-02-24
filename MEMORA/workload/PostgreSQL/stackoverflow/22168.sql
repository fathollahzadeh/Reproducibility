WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    AND 
        p.ViewCount > (SELECT AVG(ViewCount) FROM Posts WHERE CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year')
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.Reputation,
        CASE 
            WHEN rp.Score IS NULL OR rp.Score = 0 THEN 'No Score'
            WHEN rp.Reputation IS NULL OR rp.Reputation = 0 THEN 'Anonymous'
            ELSE 'Active User'
        END AS UserStatus
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(NULLIF(SUM(c.Score), 0), -1) AS TotalCommentScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Id IN (SELECT PostId FROM TopPosts)
    GROUP BY 
        p.Id
),
FinalReport AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.Reputation,
        tp.UserStatus,
        pc.CommentCount,
        pc.TotalCommentScore,
        CASE 
            WHEN pc.TotalCommentScore < 0 THEN 'Insufficient Data'
            WHEN pc.TotalCommentScore > 10 THEN 'Highly Rated'
            ELSE 'Moderately Rated'
        END AS CommentScoreStatus
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostComments pc ON tp.PostId = pc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Score,
    fr.Reputation,
    fr.UserStatus,
    fr.CommentCount,
    fr.TotalCommentScore,
    fr.CommentScoreStatus,
    CASE 
        WHEN fr.CommentCount IS NULL THEN 'No Comments Yet'
        ELSE CONCAT(fr.CommentCount, ' comments')
    END AS CommentsSummary,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fr.PostId AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = fr.PostId AND v.VoteTypeId = 3) AS DownVotes
FROM 
    FinalReport fr
ORDER BY 
    fr.Score DESC, 
    fr.CommentCount DESC;