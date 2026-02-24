WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS RankByComments,
        DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) DESC) AS RankByUpVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.CommentCount > 10 THEN 'Highly Discussed'
            WHEN rp.CommentCount BETWEEN 5 AND 10 THEN 'Moderately Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel,
        CASE 
            WHEN rp.UpVotes > 50 THEN 'Highly Upvoted'
            WHEN rp.UpVotes BETWEEN 20 AND 50 THEN 'Moderately Upvoted'
            ELSE 'Less Upvoted'
        END AS VoteLevel
    FROM 
        RankedPosts rp
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.Tags,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.DiscussionLevel,
    ps.VoteLevel,
    STRING_AGG(DISTINCT b.Name, ', ') AS BadgesEarned
FROM 
    PostStatistics ps
LEFT JOIN 
    Badges b ON ps.PostId = b.UserId 
WHERE 
    ps.UpVotes > 0
GROUP BY 
    ps.PostId, ps.Title, ps.Body, ps.Tags, ps.CreationDate, ps.CommentCount, ps.UpVotes, ps.DownVotes, ps.DiscussionLevel, ps.VoteLevel
ORDER BY 
    ps.CommentCount DESC, ps.UpVotes DESC
LIMIT 50;