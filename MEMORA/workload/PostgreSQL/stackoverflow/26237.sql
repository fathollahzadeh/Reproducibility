
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName
),
PostRanking AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerName,
        rp.AnswerCount,
        rp.UpVotes,
        rp.DownVotes,
        RANK() OVER (ORDER BY rp.AnswerCount DESC, rp.UpVotes DESC, rp.CreationDate DESC) AS Rank
    FROM 
        RankedPosts rp
)
SELECT 
    pr.Rank,
    pr.Title,
    pr.OwnerName,
    pr.AnswerCount,
    pr.UpVotes,
    pr.DownVotes
FROM 
    PostRanking pr
WHERE 
    pr.Rank <= 10 
ORDER BY 
    pr.Rank;
