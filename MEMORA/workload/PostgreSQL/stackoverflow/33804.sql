
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotesCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotesCount,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), NULL) AS AcceptedAnswerId,
        p.Tags
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.UpVotesCount,
        rp.DownVotesCount,
        rp.Tags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.PostId) AS CommentCount,
        (SELECT STRING_AGG(b.Name, ', ') 
         FROM Badges b 
         WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)) AS UserBadges
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostHistoryAggregated AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.Comment, '; ') AS CommentsHistory,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
FinalResults AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.UpVotesCount,
        pd.DownVotesCount,
        pd.CommentCount,
        pd.UserBadges,
        COALESCE(ph.CommentsHistory, 'No history available') AS CommentsHistory,
        COALESCE(ph.EditCount, 0) AS EditCount
    FROM 
        PostDetails pd
    LEFT JOIN 
        PostHistoryAggregated ph ON pd.PostId = ph.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.UpVotesCount,
    fr.DownVotesCount,
    fr.CommentCount,
    fr.UserBadges,
    fr.CommentsHistory,
    fr.EditCount
FROM 
    FinalResults fr
ORDER BY 
    fr.Score DESC, fr.ViewCount DESC;
