WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score' 
            WHEN rp.Score < 0 THEN 'Under review' 
            ELSE 'Popular Post' 
        END AS PostCategory,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT STRING_AGG(c.Text, '; ') FROM Comments c WHERE c.PostId = rp.PostId) AS CommentSummaries
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5 
),
FinalReport AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.PostCategory,
        pd.UpVotes,
        pd.DownVotes,
        COALESCE(pd.CommentSummaries, 'No comments') AS CommentSummaries,
        COALESCE((
            SELECT STRING_AGG(pht.Name, ', ') 
            FROM PostHistory ph
            JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
            WHERE ph.PostId = pd.PostId 
            AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
        ), 'No recent edits') AS RecentEdits
    FROM 
        PostDetails pd
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.ViewCount,
    fr.Score,
    fr.PostCategory,
    fr.UpVotes,
    fr.DownVotes,
    fr.CommentSummaries,
    fr.RecentEdits
FROM 
    FinalReport fr
WHERE 
    fr.SCORE IS NOT NULL
    AND fr.PostCategory = 'Popular Post'
ORDER BY 
    fr.ViewCount DESC,
    fr.CreationDate DESC
LIMIT 50;