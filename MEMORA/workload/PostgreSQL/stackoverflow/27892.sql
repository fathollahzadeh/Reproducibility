
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT t.TagName, ', ') AS RelevantTags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tag_names ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_names
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        RANK() OVER (ORDER BY SUM(u.UpVotes) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CommentCount,
    tp.AnswerCount,
    tp.LastEditDate,
    tp.RelevantTags,
    tu.DisplayName AS TopUser,
    tu.TotalBadges,
    tu.TotalBounties
FROM 
    TaggedPosts tp
JOIN 
    TopUsers tu ON tu.UserRank = 1
ORDER BY 
    tp.LastEditDate DESC, 
    tp.CommentCount DESC;
