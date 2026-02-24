WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
PostDetails AS (
    SELECT 
        rp.Id AS PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CreationDate,
        u.DisplayName AS OwnerName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = rp.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank = 1 
),
ClosedPostHistories AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        ctr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ph.Comment::int = ctr.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
),
AggregatePostData AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Score,
        pd.ViewCount,
        pd.CreationDate,
        pd.OwnerName,
        pd.CommentCount,
        pd.UpVoteCount,
        pd.DownVoteCount,
        COALESCE(cph.CloseReason, 'Not Closed') AS CloseReason,
        SUM(pd.UpVoteCount - pd.DownVoteCount) OVER () AS NetVotes
    FROM 
        PostDetails pd
    LEFT JOIN 
        ClosedPostHistories cph ON pd.PostId = cph.PostId
)
SELECT 
    apd.OwnerName,
    COUNT(*) AS TotalPosts,
    AVG(apd.Score) AS AvgScore,
    SUM(apd.ViewCount) AS TotalViews,
    SUM(apd.CommentCount) AS TotalComments,
    MAX(apd.CreationDate) AS LatestPost,
    STRING_AGG(DISTINCT apd.CloseReason, ', ') AS CloseReasons
FROM 
    AggregatePostData apd
GROUP BY 
    apd.OwnerName
HAVING 
    COUNT(*) > 5 
ORDER BY 
    AvgScore DESC;