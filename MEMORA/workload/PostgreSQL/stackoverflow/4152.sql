
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '>')) AS TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(p.Tags, '>'))
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostActivity AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostNumber,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalUpVotes,
    us.TotalDownVotes,
    pt.TagName AS PopularTag,
    pa.Title AS RecentPostTitle,
    pa.CreationDate AS PostCreationDate,
    pa.CommentCount,
    pa.TotalBounty
FROM 
    UserStatistics us
JOIN 
    PopularTags pt ON 1=1
JOIN 
    PostActivity pa ON us.UserId = pa.OwnerUserId
WHERE 
    us.Reputation > 1000
    AND (pa.RecentPostNumber = 1 OR pa.RecentPostNumber IS NULL)
ORDER BY 
    us.Reputation DESC,
    pa.TotalBounty DESC
LIMIT 50;
