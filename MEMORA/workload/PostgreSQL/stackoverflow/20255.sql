
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS RecentTagRank,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId, p.Tags
),
FilteredPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.ScoreRank,
        rp.RecentTagRank,
        (UPV.UpvoteCount - DPV.DownvoteCount) AS NetVotes
    FROM 
        RankedPosts rp
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) UPV ON rp.PostID = UPV.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
        FROM 
            Votes
        GROUP BY 
            PostId
    ) DPV ON rp.PostID = DPV.PostId
    WHERE 
        rp.CommentCount > 0
        AND NOT EXISTS (
            SELECT 1 
            FROM Posts AS subp 
            WHERE subp.ParentId = rp.PostID AND subp.PostTypeId = 2
            HAVING COUNT(*) > 10
        )
),
FinalResults AS (
    SELECT 
        fp.*,
        CASE 
            WHEN fp.ScoreRank = 1 THEN 'Top Post'
            WHEN fp.ScoreRank <= 5 THEN 'High Score Post'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        FilteredPosts fp
    WHERE 
        fp.NetVotes > 0
)
SELECT 
    fr.PostID,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.CommentCount,
    fr.NetVotes,
    fr.PostCategory,
    CASE 
        WHEN fr.CommentCount IN (SELECT COUNT(*) FROM Comments GROUP BY PostId HAVING COUNT(*) > 0)
        THEN 'Has Comments'
        ELSE 'No Comments' 
    END AS CommentStatus
FROM 
    FinalResults fr
WHERE 
    fr.CreationDate < (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    AND fr.PostCategory <> 'Top Post'
ORDER BY 
    fr.CreationDate DESC
LIMIT 100;
