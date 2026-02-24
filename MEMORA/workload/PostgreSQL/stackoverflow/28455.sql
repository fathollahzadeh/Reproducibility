WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.Reputation AS OwnerReputation,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY u.Reputation DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.Reputation
),
MostVotedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerReputation,
        mv.TotalVotes
    FROM 
        RankedPosts rp
    JOIN 
        MostVotedPosts mv ON rp.Id = mv.Id
    ORDER BY 
        mv.TotalVotes DESC, rp.ViewCount DESC
    LIMIT 10 
),
PostComments AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(c.Text, ' | ') AS Comments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.OwnerReputation,
    tp.TotalVotes,
    pc.Comments
FROM 
    TopPosts tp
LEFT JOIN 
    PostComments pc ON tp.Id = pc.PostId
ORDER BY 
    tp.TotalVotes DESC, tp.ViewCount DESC;