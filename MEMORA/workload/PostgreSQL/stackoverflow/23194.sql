
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.PostTypeId) AS UniquePostTypes,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.DisplayName
), 
ActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts,
        UniquePostTypes,
        PositivePosts,
        NegativePosts,
        AverageBounty,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
), 
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        PH.PostHistoryTypeId,
        COUNT(PH.Id) AS HistoryCount,
        STRING_AGG(PH.UserDisplayName || ' -> ' || PH.Comment, '; ') AS EditComments,
        MAX(PH.CreationDate) AS LastEdited
    FROM 
        Posts p
    JOIN 
        PostHistory PH ON p.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        p.Id, p.Title, PH.PostHistoryTypeId
)
SELECT 
    au.UserId,
    au.DisplayName,
    au.TotalPosts,
    au.UniquePostTypes,
    COALESCE(ps.PostId, -1) AS PostId,
    COALESCE(ps.Title, 'No Posts') AS Title,
    COALESCE(ps.HistoryCount, 0) AS HistoryChanges,
    COALESCE(ps.EditComments, 'No edits') AS RecentEditComments,
    CASE 
        WHEN au.PositivePosts > au.NegativePosts THEN 'Contributing Positive'
        WHEN au.PositivePosts < au.NegativePosts THEN 'Facing Criticism'
        ELSE 'Neutral'
    END AS UserContributionStatus,
    CASE 
        WHEN au.AverageBounty IS NULL THEN 'No Bounty Activity'
        ELSE 'Average Bounty: ' || CAST(au.AverageBounty AS VARCHAR)
    END AS BountyStatus
FROM 
    ActiveUsers au
LEFT JOIN 
    PostHistoryStats ps ON au.UserId = (SELECT p.OwnerUserId FROM Posts AS p ORDER BY p.CreationDate DESC LIMIT 1)
WHERE 
    au.Rank <= 10
ORDER BY 
    au.Rank;
