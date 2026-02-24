WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) as PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopQuestions AS (
    SELECT 
        rp.Id, 
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        ARRAY_LENGTH(string_to_array(rp.Tags, '>'), 1) AS TagCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10 
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    tq.Score,
    tq.TagCount,
    ue.UserId,
    ue.Reputation,
    ue.CommentCount,
    ue.UpVoteCount,
    ue.DownVoteCount
FROM 
    TopQuestions tq
JOIN 
    UserEngagement ue ON ue.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = tq.Id)
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;