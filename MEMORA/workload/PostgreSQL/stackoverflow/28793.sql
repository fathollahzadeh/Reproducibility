
WITH TagArray AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,  
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount, 
        SUM(CASE WHEN v.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotesGiven 
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        ta.Tag,
        COUNT(ta.PostId) AS TagUsageCount
    FROM 
        TagArray ta
    GROUP BY 
        ta.Tag
    ORDER BY 
        TagUsageCount DESC
    LIMIT 10  
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.AnswerCount,
    pd.CommentCount,
    pd.OwnerDisplayName,
    COALESCE(pt.Tag, 'Uncategorized') AS Tag,
    pd.UpVotes,
    pd.DownVotes,
    us.UpVotesCount,
    us.DownVotesCount,
    us.TotalVotesGiven
FROM 
    PostDetails pd
LEFT JOIN 
    PopularTags pt ON pd.Title ILIKE '%' || pt.Tag || '%'  
LEFT JOIN 
    UserVoteStats us ON pd.OwnerDisplayName = us.DisplayName
ORDER BY 
    pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 50;
