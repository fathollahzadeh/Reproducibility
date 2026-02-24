WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '<>')) AS t(TagName) ON true
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, t.TagName
),
RankedPosts AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY TagName ORDER BY VoteCount DESC, UpVotes DESC) AS Rank
    FROM 
        PostStatistics
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    VoteCount,
    UpVotes,
    DownVotes,
    TagName
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    TagName, Rank;