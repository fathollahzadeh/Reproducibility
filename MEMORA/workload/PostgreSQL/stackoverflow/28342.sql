WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.LastActivityDate,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted'
        END AS AcceptanceStatus,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.LastActivityDate DESC) AS UserPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.ViewCount > 100 
),
TagDetails AS (
    SELECT 
        p.Id AS PostId,
        string_agg(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON p.Id = p.Id
    GROUP BY 
        p.Id
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.LastActivityDate,
    rp.CreationDate,
    rp.Body,
    rp.OwnerDisplayName,
    rp.AcceptanceStatus,
    td.Tags,
    ue.TotalVotes,
    ue.UpVotes,
    ue.DownVotes,
    CASE 
        WHEN rp.UserPostRank = 1 THEN 'Latest Active Post'
        ELSE 'Other Posts'
    END AS PostRanking
FROM 
    RankedPosts rp
JOIN 
    TagDetails td ON rp.PostId = td.PostId
JOIN 
    Users u ON rp.OwnerDisplayName = u.DisplayName
JOIN 
    UserEngagement ue ON u.Id = ue.UserId
ORDER BY 
    rp.LastActivityDate DESC
LIMIT 100;