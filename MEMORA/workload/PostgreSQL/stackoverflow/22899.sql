WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE(v.VoteCount, 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(VoteTypeId) AS VoteCount 
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.PostTypeId,
        rp.CreationDate,
        rp.PostRank,
        rp.TotalVotes,
        CASE 
            WHEN rp.PostTypeId = 1 AND rp.TotalVotes > 10 THEN 'Popular Question'
            WHEN rp.PostTypeId = 2 AND rp.TotalVotes > 5 THEN 'Trending Answer'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(Id) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON u.Id = b.UserId
)
SELECT 
    fp.Title,
    fp.TotalVotes,
    ud.DisplayName,
    ud.Reputation,
    ud.BadgeCount,
    fp.PostCategory
FROM 
    FilteredPosts fp
LEFT JOIN 
    Users u ON fp.PostTypeId = u.Id
LEFT JOIN 
    UserDetails ud ON u.Id = ud.UserId
WHERE 
    u.Reputation IS NOT NULL AND 
    (ud.BadgeCount IS NULL OR ud.BadgeCount > 0) AND
    (fp.TotalVotes > 2 OR fp.PostCategory = 'Popular Question')
ORDER BY 
    fp.TotalVotes DESC, 
    fp.CreationDate DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;