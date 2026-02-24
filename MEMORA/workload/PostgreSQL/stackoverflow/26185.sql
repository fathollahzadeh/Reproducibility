WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(CONCAT_WS(',', 'tag1', 'tag2', 'tag3')) AS TagCount,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVoteCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)    
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, p.Tags
), UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(rp.TagCount) AS TotalTags,
        SUM(rp.CommentCount) AS TotalComments,
        AVG(rp.UpVoteCount) AS AverageUpVotes,
        COUNT(rp.PostId) AS TotalPosts,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalTags,
    us.TotalComments,
    us.AverageUpVotes,
    us.UserRank,
    CASE 
        WHEN us.Reputation > 1000 THEN 'High Reputation'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation' 
    END AS ReputationCategory
FROM 
    UserStats us
WHERE 
    us.TotalPosts > 5
ORDER BY 
    us.UserRank;