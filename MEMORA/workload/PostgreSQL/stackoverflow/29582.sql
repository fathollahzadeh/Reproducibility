
WITH PostTagStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(pt.Name, 'No Tags') AS TagName,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Tags t ON t.TagName = ANY(string_to_array(TRIM(BOTH '<>' FROM REPLACE(p.Tags, '><', '>')), '>'))
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    LEFT JOIN 
        PostHistoryTypes pt ON pt.Id = ph.PostHistoryTypeId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Tags, pt.Name
),
Ranking AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        OwnerUserId,
        Tags,
        ViewCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        TagName,
        CommentCount,
        RANK() OVER (ORDER BY (ViewCount + UpVotes - DownVotes) DESC) AS PostRanking 
    FROM 
        PostTagStats
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.OwnerUserId,
    r.Tags,
    r.ViewCount,
    r.AnswerCount,
    r.UpVotes,
    r.DownVotes,
    r.TagName,
    r.CommentCount,
    r.PostRanking,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    COUNT(DISTINCT b.Id) AS BadgeCount 
FROM 
    Ranking r
JOIN 
    Users u ON u.Id = r.OwnerUserId
LEFT JOIN 
    Badges b ON b.UserId = u.Id
GROUP BY 
    r.PostId, r.Title, r.CreationDate, r.OwnerUserId, r.Tags, r.ViewCount, r.AnswerCount, 
    r.UpVotes, r.DownVotes, r.TagName, r.CommentCount, r.PostRanking, u.DisplayName, u.Reputation
ORDER BY 
    r.PostRanking
LIMIT 10;
