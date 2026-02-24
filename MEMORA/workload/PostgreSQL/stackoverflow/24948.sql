WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(v.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.RankScore,
        rp.VoteCount,
        rp.UpVoteCount,
        rp.DownVoteCount,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment AS CloseReason
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    WHERE 
        rp.RankScore <= 5 
),
TagDetails AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        p.Id AS PostId
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
),
FinalResult AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.OwnerDisplayName,
        pd.CreationDate,
        pd.ViewCount,
        pd.Score,
        pd.RankScore,
        pd.VoteCount,
        pd.UpVoteCount,
        pd.DownVoteCount,
        STRING_AGG(DISTINCT td.TagName, ', ') AS Tags,
        CASE 
            WHEN pd.CloseReason IS NOT NULL THEN 'Closed: ' || pd.CloseReason 
            ELSE 'Open' 
        END AS PostStatus
    FROM 
        PostDetails pd
    LEFT JOIN 
        TagDetails td ON pd.PostId = td.PostId
    GROUP BY 
        pd.PostId, pd.Title, pd.OwnerDisplayName, pd.CreationDate, pd.ViewCount, 
        pd.Score, pd.RankScore, pd.VoteCount, pd.UpVoteCount, pd.DownVoteCount,
        pd.CloseReason
)
SELECT 
    *,
    CASE 
        WHEN ViewCount > 1000 THEN 'Highly Viewed'
        WHEN ViewCount BETWEEN 500 AND 1000 THEN 'Moderately Viewed'
        ELSE 'Less Viewed' 
    END AS ViewCategory,
    CASE 
        WHEN UpVoteCount = 0 AND DownVoteCount > 0 THEN 'Negative Feedback'
        WHEN UpVoteCount > DownVoteCount THEN 'Positive Feedback'
        ELSE 'Mixed Feedback' 
    END AS FeedbackCategory
FROM 
    FinalResult
ORDER BY 
    Score DESC, ViewCount DESC;