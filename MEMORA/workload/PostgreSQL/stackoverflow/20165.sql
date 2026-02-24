WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
TopPostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(BadgeCount.BadgeCount, 0) AS BadgeCount
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS BadgeCount
        FROM 
            Badges 
        GROUP BY 
            UserId
    ) AS BadgeCount ON u.Id = BadgeCount.UserId
    WHERE 
        rp.rn = 1
)
SELECT 
    tpd.PostId,
    tpd.Title,
    tpd.CommentCount,
    tpd.UpVotes,
    tpd.DownVotes,
    tpd.OwnerDisplayName,
    tpd.BadgeCount,
    CASE 
        WHEN tpd.UpVotes > tpd.DownVotes THEN 'Popular'
        WHEN tpd.UpVotes = tpd.DownVotes AND tpd.CommentCount > 0 THEN 'Engaging'
        ELSE 'Less Engaging'
    END AS EngagementLevel,
    CASE 
        WHEN tpd.BadgeCount > 0 THEN 'Badged User'
        ELSE 'Non-Badged User'
    END AS UserType
FROM 
    TopPostDetails tpd
ORDER BY 
    tpd.UpVotes DESC, tpd.CommentCount DESC
LIMIT 10;