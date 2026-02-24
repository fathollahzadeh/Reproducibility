
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.PostTypeId
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.ScoreRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.Text, '; ') AS CommentTexts
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResult AS (
    SELECT 
        fp.*, 
        pc.CommentCount,
        pc.CommentTexts,
        CASE 
            WHEN fp.UpVotes > fp.DownVotes THEN 'Positive'
            WHEN fp.UpVotes = fp.DownVotes THEN 'Neutral'
            ELSE 'Negative'
        END AS PostSentiment,
        (SELECT COUNT(DISTINCT bh.UserId) 
         FROM Badges bh 
         WHERE bh.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts 
                             WHERE Id = fp.PostId) 
         AND bh.Class = 1) AS GoldBadgeCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostComments pc ON fp.PostId = pc.PostId
)
SELECT 
    p.PostId, 
    p.Title, 
    p.CreationDate, 
    p.ViewCount, 
    p.Score,
    p.UpVotes,
    p.DownVotes,
    p.CommentCount,
    p.CommentTexts,
    p.PostSentiment,
    p.GoldBadgeCount
FROM 
    FinalResult p
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 10;
