
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score IS NOT NULL
),
PostVoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    INNER JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.UserDisplayName, ' (', ph.CreationDate, '): ', ph.Comment), '; ') AS HistoryComments
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12, 13)
    GROUP BY 
        ph.PostId
),
FinalSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        COALESCE(pvs.Upvotes, 0) AS TotalUpvotes,
        COALESCE(pvs.Downvotes, 0) AS TotalDownvotes,
        COALESCE(phd.HistoryComments, 'No history') AS PostHistory
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVoteSummary pvs ON rp.PostId = pvs.PostId
    LEFT JOIN 
        PostHistoryDetails phd ON rp.PostId = phd.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    *,
    CASE 
        WHEN TotalUpvotes > TotalDownvotes THEN 'Positive' 
        WHEN TotalUpvotes < TotalDownvotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment,
    CASE 
        WHEN LENGTH(PostHistory) > 100 THEN 'Has a rich history of modifications' 
        ELSE 'Few modifications' 
    END AS HistoryDescription
FROM 
    FinalSummary
ORDER BY 
    ViewCount DESC;
