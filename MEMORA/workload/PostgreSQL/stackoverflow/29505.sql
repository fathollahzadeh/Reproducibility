
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagList,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Tags t ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT bh.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges bh ON u.Id = bh.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalUpVotes DESC
    LIMIT 5
),
PostEngagement AS (
    SELECT 
        p.PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.TagList,
        p.CommentCount,
        p.AnswerCount,
        u.UserId,
        u.DisplayName AS UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostId ORDER BY u.TotalUpVotes DESC) AS UserRank
    FROM 
        RecentPosts p
    JOIN 
        TopUsers u ON TRUE
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.Score,
    pe.ViewCount,
    pe.TagList,
    pe.CommentCount,
    pe.AnswerCount,
    pe.UserId,
    pe.UserDisplayName,
    pe.UserRank
FROM 
    PostEngagement pe
WHERE 
    pe.UserRank <= 3
ORDER BY 
    pe.PostId, pe.UserRank;
