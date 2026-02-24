WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (4, 5)  
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score
),
RankedPosts AS (
    SELECT 
        ps.*,
        DENSE_RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY ps.ViewCount DESC) AS ViewRank
    FROM 
        PostStats ps
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.UpVotes > 0 THEN (rp.UpVotes * 1.0 / NULLIF(rp.UpVotes + rp.DownVotes, 0)) * 100 
            ELSE 0 
        END AS UpvotePercentage
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 10 OR rp.ViewRank <= 10
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.UpVotes,
    fp.DownVotes,
    fp.CommentCount,
    fp.EditCount,
    fp.UpvotePercentage,
    CASE 
        WHEN fp.UpvotePercentage IS NOT NULL THEN 
            CASE 
                WHEN fp.UpvotePercentage >= 75 THEN 'High Quality'
                WHEN fp.UpvotePercentage >= 50 THEN 'Moderate Quality'
                ELSE 'Low Quality'
            END
        ELSE 'No Votes'
    END AS QualityAssessment
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;