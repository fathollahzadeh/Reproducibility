WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS AccountCreated
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
),
PostWithUserInfo AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Score,
        fp.ViewCount,
        ru.UserId,
        ru.DisplayName AS UserDisplayName,
        ru.BadgeCount
    FROM 
        FilteredPosts fp
    JOIN 
        Posts p ON fp.PostId = p.Id
    LEFT JOIN 
        RecentUsers ru ON p.OwnerUserId = ru.UserId
)
SELECT 
    pwfi.PostId,
    pwfi.Title,
    pwfi.Score,
    pwfi.ViewCount,
    pwfi.UserDisplayName,
    pwfi.BadgeCount,
    CASE 
        WHEN pwfi.BadgeCount > 5 THEN 'High Achiever'
        WHEN pwfi.BadgeCount BETWEEN 1 AND 5 THEN 'Moderate User'
        ELSE 'New User'
    END AS UserType,
    CASE 
        WHEN pwfi.Score IS NULL THEN 'No Score'
        ELSE 'Scored'
    END AS PostScoreStatus
FROM 
    PostWithUserInfo pwfi
ORDER BY 
    pwfi.Score DESC NULLS LAST;