WITH PostActivity AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
), RankedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        LastActivityDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC, UpVotes DESC) AS Rank
    FROM 
        PostActivity
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.BadgeCount > 5 THEN 'Expert Contributor'
        WHEN rp.BadgeCount > 2 THEN 'Active Contributor'
        ELSE 'New Contributor'
    END AS ContributorLevel
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 50
ORDER BY 
    rp.Rank;