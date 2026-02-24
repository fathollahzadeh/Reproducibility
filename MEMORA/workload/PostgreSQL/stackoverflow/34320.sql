WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.ViewCount > 50
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, pt.Name
),
TopPosts AS (
    SELECT 
        rp.Id, 
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
    GROUP BY 
        b.UserId
),
UserDetails AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        ub.BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    td.UserId,
    td.DisplayName,
    td.Reputation,
    td.BadgeCount,
    tp.Title AS TopPostTitle,
    tp.ViewCount AS TopPostViewCount,
    tp.Score AS TopPostScore,
    tp.CommentCount AS TopPostCommentCount,
    tp.UpVotes AS TopPostUpVotes,
    tp.DownVotes AS TopPostDownVotes
FROM 
    TopPosts tp
JOIN 
    UserDetails td ON tp.Id = td.UserId
ORDER BY 
    td.Reputation DESC, 
    tp.Score DESC
LIMIT 10;