WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) DESC) AS VoteRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
TopVotedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.VoteRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.VoteRank <= 10
)
SELECT 
    tvp.PostId,
    tvp.Title,
    tvp.CreationDate,
    tvp.OwnerDisplayName,
    tvp.CommentCount,
    tvp.AnswerCount,
    tvp.UpVotes,
    tvp.DownVotes,
    (tvp.UpVotes - tvp.DownVotes) AS NetVotes,
    COUNT(DISTINCT ph.Id) AS EditCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    TopVotedPosts tvp
LEFT JOIN 
    PostHistory ph ON tvp.PostId = ph.PostId
GROUP BY 
    tvp.PostId, tvp.Title, tvp.CreationDate, tvp.OwnerDisplayName, tvp.CommentCount, tvp.AnswerCount, tvp.UpVotes, tvp.DownVotes
ORDER BY 
    NetVotes DESC, tvp.CreationDate DESC;