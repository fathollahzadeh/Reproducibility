WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE(c.UserId, -1) AS MostRecentCommentUserId,
        COALESCE(c.CreationDate, '1900-01-01'::timestamp) AS RecentCommentDate
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, UserId, CreationDate 
         FROM Comments 
         WHERE UserId IS NOT NULL 
         ORDER BY CreationDate DESC) c 
    ON p.Id = c.PostId
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.RankScore,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes,  
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes,  
        (SELECT COUNT(*) FROM Comments cm WHERE cm.PostId = rp.PostId) AS CommentCount,
        CASE 
            WHEN rp.RankScore = 1 THEN 'Top'
            WHEN rp.RankScore < 5 THEN 'High'
            ELSE 'Moderate'
        END AS Popularity
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankScore <= 10
),
ClosedPostComments AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS CloseComments,
        ARRAY_AGG(DISTINCT ph.Comment) AS CloseReasonComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        COALESCE(cpc.CloseComments, 0) AS CloseComments,
        COALESCE(cpc.CloseReasonComments, ARRAY[]::text[]) AS CloseReasons,
        CASE 
            WHEN ps.CommentCount > 0 THEN TRUE
            ELSE FALSE
        END AS HasComments
    FROM 
        PostStats ps
    LEFT JOIN 
        ClosedPostComments cpc ON ps.PostId = cpc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.ViewCount,
    fr.Score,
    fr.UpVotes,
    fr.DownVotes,
    fr.CommentCount,
    fr.CloseComments,
    fr.CloseReasons,
    fr.HasComments,
    CASE 
        WHEN fr.Score > 10 AND fr.CloseComments = 0 THEN 'Active'
        WHEN fr.Score <= 10 AND fr.CloseComments > 0 THEN 'Needs Attention'
        ELSE 'Neutral'
    END AS Status
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, 
    fr.ViewCount DESC
LIMIT 50;