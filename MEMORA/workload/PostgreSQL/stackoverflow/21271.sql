
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        pt.Name AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(pc.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments pc ON p.Id = pc.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name, p.OwnerUserId, p.CreationDate
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesCount,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation'
            WHEN u.Reputation IS NULL THEN 'No Reputation'
            ELSE 'Norm'
        END AS ReputationCategory
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
UserPostSummary AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.TotalBounties,
        ua.UpvotesCount,
        ua.DownvotesCount,
        MAX(rp.Rank) AS MaxPostRank,
        COUNT(rp.PostId) AS PostCount,
        AVG(rp.CommentCount) AS AvgComments
    FROM 
        UserActivity ua
    JOIN 
        RankedPosts rp ON ua.UserId = rp.OwnerUserId
    GROUP BY 
        ua.UserId, ua.DisplayName, ua.TotalBounties, ua.UpvotesCount, ua.DownvotesCount
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalBounties,
    ups.UpvotesCount,
    ups.DownvotesCount,
    ups.MaxPostRank,
    ups.PostCount,
    ups.AvgComments,
    CASE 
        WHEN ups.PostCount = 0 THEN 'No Posts'
        WHEN ups.MaxPostRank < 3 THEN 'Active User'
        ELSE 'Inactive User'
    END AS UserActivityLevel 
FROM 
    UserPostSummary ups
WHERE 
    ups.TotalBounties > 0 
    OR ups.UpvotesCount > ups.DownvotesCount
ORDER BY 
    ups.TotalBounties DESC, ups.PostCount DESC
LIMIT 10;
