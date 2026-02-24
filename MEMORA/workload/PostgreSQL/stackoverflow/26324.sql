WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS Author,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Title IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, pt.Name
    HAVING 
        COUNT(c.Id) > 5 
        AND COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) > 10
),

RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY UpVotes DESC, CommentCount DESC) AS Rank
    FROM 
        FilteredPosts
)

SELECT 
    PostId,
    Title,
    Body,
    Tags,
    CreationDate,
    Author,
    PostType,
    CommentCount,
    UpVotes,
    DownVotes,
    BadgeCount,
    Rank
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Rank;