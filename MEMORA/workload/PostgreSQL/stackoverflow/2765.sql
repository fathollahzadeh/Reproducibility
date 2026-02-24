
WITH RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpvotes,
        SUM(u.DownVotes) AS TotalDownvotes,
        RANK() OVER (ORDER BY SUM(u.UpVotes) DESC) AS UserRank
    FROM 
        Users u
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(u.UpVotes) > 0
),
PostsWithOwnerInfo AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        ru.DisplayName AS OwnerDisplayName,
        rp.CommentCount,
        rp.AverageBounty,
        tu.TotalUpvotes,
        tu.TotalDownvotes,
        tu.UserRank
    FROM 
        RecentPosts rp
    JOIN 
        Users ru ON rp.OwnerUserId = ru.Id
    LEFT JOIN 
        TopUsers tu ON ru.Id = tu.Id
)
SELECT 
    pwi.*,
    CASE 
        WHEN pwi.AverageBounty IS NULL THEN 'No Bounty'
        ELSE CONCAT('Average Bounty: $', COALESCE(CAST(pwi.AverageBounty AS TEXT), '0'))
    END AS BountyInfo,
    CASE 
        WHEN pwi.CommentCount > 10 THEN 'Highly Engaged'
        ELSE 'Less Engaged'
    END AS EngagementLevel
FROM 
    PostsWithOwnerInfo pwi
WHERE 
    EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = pwi.Id AND v.VoteTypeId IN (2, 3) 
    )
ORDER BY 
    pwi.CreationDate DESC
LIMIT 50;
