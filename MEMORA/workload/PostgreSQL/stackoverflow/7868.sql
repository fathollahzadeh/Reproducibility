
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COALESCE((SELECT COUNT(*) FROM Posts a WHERE a.AcceptedAnswerId = p.Id), 0) AS AcceptedAnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.OwnerDisplayName,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.AcceptedAnswerCount,
        RANK() OVER (ORDER BY pd.ViewCount DESC, pd.UpVotes DESC) AS Rank
    FROM 
        PostDetails pd
)

SELECT 
    tp.*,
    CASE 
        WHEN tp.AcceptedAnswerCount > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS HasAcceptedAnswer
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
