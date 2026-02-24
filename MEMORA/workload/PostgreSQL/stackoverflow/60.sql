
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY t.Id ORDER BY p.CreationDate DESC) AS rn,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.PostTypeId = 1
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalPosts,
        us.UpVotes,
        us.DownVotes,
        us.BadgeCount,
        DENSE_RANK() OVER (ORDER BY us.TotalPosts DESC, us.UpVotes - us.DownVotes DESC) AS UserRank
    FROM 
        UserStats us
    WHERE 
        us.TotalPosts > 10
)
SELECT 
    tp.UserRank,
    tp.DisplayName,
    tp.TotalPosts,
    tp.UpVotes,
    tp.DownVotes,
    tp.BadgeCount,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    CASE 
        WHEN rp.rn = 1 THEN 'Latest'
        ELSE 'Older'
    END AS PostStatus
FROM 
    TopUsers tp
LEFT JOIN 
    RankedPosts rp ON tp.UserId = rp.PostId
ORDER BY 
    tp.UserRank, 
    rp.CreationDate DESC;
