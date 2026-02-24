
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 2 THEN p.Score ELSE 0 END) AS AnswerScore,
        MAX(p.CreationDate) AS LastActiveDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosureCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
RankedPosts AS (
    SELECT 
        pe.PostId,
        pe.Title,
        pe.CommentCount,
        pe.TotalViews,
        cp.ClosureCount,
        RANK() OVER (ORDER BY pe.TotalViews DESC, pe.AnswerScore DESC) AS ViewRank
    FROM 
        PostEngagement pe
    LEFT JOIN 
        ClosedPosts cp ON pe.PostId = cp.PostId
    WHERE 
        pe.CommentCount > 5
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CommentCount,
    rp.TotalViews,
    rp.ClosureCount,
    ups.Upvotes,
    ups.Downvotes,
    ups.TotalBounty,
    CONCAT('User: ', ups.DisplayName, ' engaged with Post: "', rp.Title, '" (', rp.CommentCount, ' comments, ', rp.TotalViews, ' views)') AS EngagementSummary
FROM 
    UserVoteStats ups
JOIN 
    Posts p ON ups.UserId = p.OwnerUserId
JOIN 
    RankedPosts rp ON p.Id = rp.PostId
WHERE 
    (ups.Upvotes - ups.Downvotes) > 0 
    AND rp.ViewRank <= 10 
    AND (rp.ClosureCount IS NULL OR rp.ClosureCount < 2) 
ORDER BY 
    ups.TotalBounty DESC, rp.TotalViews DESC;
